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

What these demos prove is **memory-safety and field-canonical-range
preservation** (plus the absence of UB/overflow that Forge proves for every
program), *not* full functional correctness of the transform — i.e. the verified
contract is "this NTT never reads out of bounds and never lets an M31 element
leave `[0, P)`," not "this NTT computes the mathematically correct evaluation."
That deeper claim is what the [felt252 stack](verified-stark-crypto.md) carries
for the crypto primitives (e.g. `felt252_mul`'s `(result·R) % P == (a·b) % P`),
and the same techniques extend here at proportional cost. For an accelerated
prover the safety+range contract is already the high-value one: it is precisely
the class of bug that differential testing against a reference catches late and
that a verified emit rules out by construction.

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
