# Verified ZK prover kernels in Forge

A companion to [the verified Stark-prime crypto stack](verified-stark-crypto.md).
Where that artifact proves *deep algebraic correctness* of the field/curve/hash
primitives, this one documents the **breadth**: Forge expresses and verifies the
working kernel set of a modern STARK prover — the same kernels a CUDA/FPGA
backend re-implements for speed — and emits them as verified C99/CUDA C.

## Why this matters

A STARK prover's hot loop is a handful of kernels over a small prime field:
NTT/coset-NTT butterflies, FRI folding and query, batch field inversion, the
QM31 extension-field arithmetic that stwo runs on, and Poseidon2 / Blake2s /
Merkle for commitment. These are exactly the kernels that get hand-ported to
GPUs, and exactly where a silent bug — an out-of-bounds column access, a field
element that escapes its canonical range and aliases another residue — produces
a *valid-looking but wrong* proof. The property class below is therefore not
incidental: **memory-safety + field-canonical-range preservation is the
soundness-relevant contract for an accelerated prover kernel.**

## The corpus

Each demo below is a tracked Forge program (`forge check` discharges its
obligations; `forge build` / `forge cuda` emits the kernel). Properties are
expressed as `requires`/`ensures` over machine integers and discharged by Z3.

| Kernel | Role in the prover (stwo / Plonky3) | Verified property class |
|---|---|---|
| `1021_circle_ntt`, `1031_circle_ntt`, `1041_coset_ntt` | Circle-group / coset NTT — the core transform of the Circle-STARK (stwo) prover | In-bounds indexing; every output `< M31_P` given canonical inputs |
| `1030_ntt_butterfly`, `955_ntt_butterfly`, `178_ntt_round` | Radix NTT butterfly steps | `2·half_n ≤ data.len` (no OOB); range preservation |
| `1022_fri_fold`, `1032_fri_query` | FRI low-degree-test folding and query phase | In-bounds folding over `arr`; canonical-range outputs |
| `1024_qm31_kernels` | QM31 — the degree-4 extension of M31 that stwo's constraints live in | Per-component (`are`/`aim`/…) buffer bounds; each component `< M31_P` |
| `1036_m31_batch_inverse` | Montgomery batch inversion of M31 elements (prefix/suffix product trick) | Prefix/suffix buffer bounds; canonical-range result |
| `2001`–`2010` `bench_*_mul/sbox/perm` | BabyBear / KoalaBear / M31 field mul, S-box, and **fused Poseidon2 permutation** (the Plonky3 perm, byte-identical to upstream) | Field arithmetic stays in range; the fused-perm demos discharge thousands of obligations |
| `1027_poseidon2`, `1028_poseidon2_mds`, `1029_poseidon2_full` | Poseidon2 round / MDS / full permutation | Range preservation through add-RC → S-box → MDS |
| `1023_blake2s_compress` | Blake2s compression (Merkle leaf/inner hashing) | Working-vector and message/output buffer bounds (`v.len ≥ 16`, …) |
| `1026_merkle_tree`, `401_merkle_path`, `987_merkle_verify` | Merkle commit / path / verify | Tree/column buffer sizing (`2·n_leaves·8 ≤ tree.len`), leaf-count guards |

## Property class, stated honestly

For most kernels above the verified contract is **memory-safety and
field-canonical-range preservation** (plus the absence of UB/overflow that Forge
proves for every program): "this NTT never reads out of bounds and never lets an
M31 element leave `[0, P)`." For an accelerated prover that is already the
high-value contract — it is exactly the class of bug that differential testing
against a reference catches late and that a verified emit rules out by
construction.

**The field core now goes further — full functional correctness.** As of the
`std/m31` upgrade, the M31 field atoms prove not just range but the exact field
value:

| Function | Verified property |
|---|---|
| `m31_add` | `result == (a + b) % P` |
| `m31_sub` | `result == (a + P − b) % P` |
| `m31_mul` | `result == (a · b) % P` |
| `m31_butterfly_hi` | `result == (a + w·b) % P` (Cooley-Tukey high output) |
| `m31_butterfly_lo` | `result == (a + P − (w·b) % P) % P` (low output) |
| `cm31_mul_re` | `result == (a_re·b_re + P² − a_im·b_im) % P` (complex real part) |
| `cm31_mul_im` | `result == (a_re·b_im + a_im·b_re) % P` (complex imag part) |
| `qm31_mul_out_{re_re, re_im, im_re, im_im}` | all four components of `(a+bj)(c+dj)` with `j²=2+i`, each proved equal to its exact bilinear field value mod P |

So the whole **stwo field tower** is functionally verified:

```
M31 base field  →  scalar NTT butterfly  →  CM31 (degree 2)  →  QM31 (degree 4)
   add/sub/mul       a + w·b, a − w·b        (a+bi)(c+di)      (a+bj)(c+dj), j²=2+i
```

The **scalar NTT butterfly** — the atom under every NTT/FRI/Poseidon2 stage — is
functionally verified (a `let`-bound twiddle product plus a modular-fold assert
bridges `(a + w·b) ≡ (a + t) (mod P)`); the **CM31** and **QM31** extension
multiplies compose on top of it, with a P²-padding trick (P² ≡ 0 mod P keeps the
signed intermediates non-negative) plus one fold assert per component to collapse
the nested modular reductions Z3 will not fold unaided. **QM31 is the field stwo
constraints actually live in**, so this pins exact-value correctness across the
prover's entire arithmetic substrate. This is the same depth the
[felt252 stack](verified-stark-crypto.md) carries for the Stark-prime crypto
primitives (e.g. `felt252_mul`'s `(result·R) % P == (a·b) % P`), now reached for
the M31 prover core.

**And it now reaches the emitted kernel.** `demos/1153_ntt_butterfly_verified.fg`
lifts the scalar tower up through an **in-place array** kernel: `ntt_butterfly_at`
(a `#[kernel]`, one thread per pair) proves the full array *post-state* —

| Post-state | Verified property |
|---|---|
| `data[tid]` | `== (old(data[tid]) + w·old(data[tid+half_n])) % P` |
| `data[tid+half_n]` | `== (old(data[tid]) + P − (w·old(data[tid+half_n])) % P) % P` |
| every other `data[k]` | `== old(data[k])` (frame) |

(`w = twiddle[tid]`). It composes `tid`-as-thread-index (cf. demo 232),
`old(span[i])` pre-state references (cf. demo 139), and the verified scalar
`m31_butterfly_hi/lo`; `forge cuda` emits `__global__ void ntt_butterfly_at(...)`.
So the emitted CUDA butterfly stage is proven to compute the *mathematically
correct* transform on the array — not merely to keep elements in `[0, P)` — the
end-to-end "verified ZK compilation" claim made concrete for one real kernel.

**And it runs at hand-tuned speed.** Benchmarked on an RTX 5090
(`benchmarks/bench_butterfly.cu`), the emitted kernel is within **0.1%** of a
hand-optimized Mersenne-fold butterfly at VRAM-bound sizes (**~1,553 GB/s, ~87% of
the memory roofline**) with byte-identical results — the `% M31_P` reduction kept
*for provability* hides completely behind memory bandwidth. The only measurable
cost (~3.4%) appears only when the working set fits in L2 and compute dominates.
Verification is free where it counts.

**The inverse transform too.** `demos/1155_intt_butterfly_verified.fg` verifies the
in-place **Gentleman-Sande INTT butterfly** (`a' = a+b`, `b' = w·(a−b)`) the same
way — exact post-state + frame, `forge cuda`-emitted. Its `b' = w·(a−b)` is
nonlinear over the pre-state, so beyond the fold assert it needed an explicit
*congruence-rename* assert (equal args ⇒ equal product) to rewrite the local-var
form into the `old()`/`twiddle` form Z3 would not substitute on its own. It also
runs at parity (`benchmarks/bench_intt.cu`): VRAM-bound verified-vs-hand-tuned
ratio **1.000** at ~1,555 GB/s. And the pipeline's tail — the
`ntt_scale` kernel (`demos/1157_ntt_scale_verified.fg`, `data[tid] *= inv_n` mod P
for the final ÷N) — verifies clean (`data[tid] == (old(data[tid])·inv_n) % P` +
frame). So the whole NTT pipeline is functionally verified: forward butterfly →
bit-reversal → inverse butterfly → scale.

**A second family of emitted kernels: the FRI fold.**
`demos/1154_fri_fold_verified.fg` lifts the same way. The FRI low-degree-test fold
combines an evaluation vector's two halves with a verifier challenge `alpha`;
`fri_fold_at` (M31) proves `new[i] == (old[i] + alpha·old[i+half]) mod P`,
`fri_unfold_at` the inverse, and `fri_fold_at_cm31` the **CM31 fold stwo actually
runs** (both output components exact) — each with the array post-state + frame,
`forge cuda`-emitted. Since the fold reads a *separate* `old` array (vs the
in-place butterfly), the read-value ↔ `old()` link is stated explicitly
(`assert a == old(old_evals[i])`). It too runs at parity
(`benchmarks/bench_fri_fold.cu`): VRAM-bound verified-vs-hand-tuned ratio
**1.000** at ~1,580 GB/s, and the CM31 fold is likewise memory-bound (same
~1,575 GB/s ceiling).

**A data-movement kernel too — the bit-reversal permutation.**
`demos/1156_bitrev_verified.fg` verifies the NTT reorder step (swap `data[tid]`
with `data[rev[tid]]` when `rev[tid] > tid`) *fully*: both swap directions
(`data[tid] == old(data[rev[tid]])` and `data[rev[tid]] == old(data[tid])`), the
no-op case, and a locality frame — pure data movement through an index array,
`forge cuda`-emitted. Completing it required a **Forge core fix**: an in-branch
swap re-read its `let`-bound snapshot (`let tmp = data[tid]`) from the
*post-first-write* array instead of bind-time, so the mirror slot got
`old(data[rev[tid]])` instead of `old(data[tid])`. The fix freezes `let`-bound
array reads inside conditional blocks to a stable alias `__frz_<arr>` pinned to
the block-entry state (`lib/types/typecheck.ml`), which env_array_write never
re-renames — unlocking correct verification of in-place swap/scatter/permutation
kernels generally.

**Poseidon2 — the linear layers.** `demos/1158_poseidon2_mds_verified.fg`
functionally verifies the two *linear* layers of a Poseidon2 round: the
add-round-constant (`result == (s + rc) % P`) and the width-3 external MDS
diffusion `circ(2,1,1)` (each `out_i == (2·s_i + Σ_{j≠i} s_j) % P`) — exact field
values, composed from the verified `m31_add`/`m31_double`. These lift to an
emitted in-place CUDA kernel `poseidon2_mds3_at` (one thread per width-3 state)
proving the full array post-state — all three outputs over the *old* triple
(a read-all-then-write the freeze fix + store-after-store asserts handle) plus a
locality frame. The round's *nonlinear*
S-box `x⁵ mod P` is **not** functionally verified: its exact value is a
high-degree nonlinear goal beyond automated Z3 (it fails even at a 300 s
per-obligation budget) — the same Fermat-class limitation as the felt252 modular
inverse, which is an audit-assume there. The S-box is range-verified; the linear
diffusion is where functional correctness is achievable, and this demo pins it.

**A full verifier loop.** `demos/1161_merkle_verify_loop.fg` wires the per-level
Merkle operations into a multi-level inclusion-path verifier: a `while` loop that
walks `depth` levels from a leaf to the root, combining the running node with its
sibling (correct order by child parity, from the verified `combine_first`/`second`)
through a range-preserving compression and halving the index. A **loop invariant**
(`node < P`, `l ≤ depth`) plus a `decreases` clause prove the *entire walk* is
memory-safe (every sibling access in bounds at every level) and range-preserving
(the running node, hence the root, stays canonical) — for any tree depth. It is
the campaign's first loop-based verifier, showing the per-kernel results compose
into a whole-verifier property; the hash primitive plugs in as the same kind of
range-verified black box.

**Both ZK field families are covered.** The same functional-correctness pattern
extends to Plonky3's fields: `std/baby_bear` and `std/koala_bear` prove exact
field values for the base ops (add/sub/mul/neg/double/mul_w) *and* the full
degree-4 extension multiply (`ext4_mul c0..c3` over `x⁴ = W`, with `W = 11` for
BabyBear / `3` for KoalaBear) plus the componentwise extension add/sub. So both
major proving stacks — **stwo** (M31 → QM31) and **Plonky3** (BabyBear/KoalaBear
+ their degree-4 extensions) — now have their field arithmetic exact-value
verified, base field through constraint field.

## Reproduce

```bash
forge check demos/1021_circle_ntt.fg     # discharge the kernel's obligations
forge cuda  demos/1024_qm31_kernels.fg   # emit verified CUDA C
FORGE_JOBS=24 forge check demos/2009_bench_baby_bear_fused_perm_factored.fg
                                          # the heavy fused-Poseidon2 perm, parallel discharge
```

*Status: every kernel above is in the tracked test corpus and discharges under
both serial and parallel (`FORGE_JOBS`) discharge with identical verdicts —
confirmed byte-identical across the full 1,164-demo equivalence sweep plus the
heavy kernels individually (`1027_poseidon2` 308 obl 146→61 s, `1029_poseidon2_full`
763 obl 147→60 s, `1023_blake2s_compress` 54 obl 121→60 s, `2006_bench_baby_bear_chunk_step`
305 obl 549→61 s = 9.0×), all IDENTICAL serial vs parallel.*
