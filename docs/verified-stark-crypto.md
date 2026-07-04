# Verified Stark-Prime Cryptography and Accelerated Prover Kernels in a Refinement-Typed Language with SMT Discharge

*Draft — Garrick Wagner, 2026. Artifact: `forge` / `demos/std/felt252.fg`.*

## Abstract

We report a machine-checked implementation of the full Starknet cryptographic
stack — modular arithmetic over the Stark prime `P = 2²⁵¹ + 17·2¹⁹² + 1`,
elliptic-curve group operations, the canonical Stark Pedersen and Stark Poseidon
hashes, and ECDSA signature verification — written and proved in **Forge**, a
refinement-typed systems language whose proof obligations are discharged by an
SMT solver (Z3) and which compiles to verified C99 (and GPU C). The artifact is
22,311 lines, generates **5,302 proof obligations** that are discharged
automatically, and rests on an explicitly enumerated trusted base of **39
audit assumptions**, each a named analytic fact with a documented justification
and a concrete path to mechanization. To our knowledge this is the largest
single body of machine-checked Stark-prime cryptography, and the emitted C is a
spec-correct reference suitable for differential validation of the GPU/FPGA
prover implementations on which zk-rollup throughput now depends.

The contribution is less any single proof than a **methodology for scaling
SMT-discharged verification through a region where monolithic solver queries do
not terminate**: (i) *per-limb projection* of multi-precision results, (ii) a
*witness cascade* that threads Montgomery-reduction invariants through chained
helper lemmas, (iii) *chunked induction* that uses function-call boundaries as
the escape hatch from non-terminating nonlinear queries, and (iv) a *mechanical
modulus mirror* that re-derives the entire mod-`n` (curve-order) stack from the
proven mod-`P` stack by structural substitution. We also describe the trusted
computing base (TCB) candidly, since for a cryptographic artifact the shape of
the TCB is the result that matters most.

We then present a **second case study**: applying the same language and
techniques to the *accelerated prover kernels* on which zk-rollup throughput
depends. We functionally verify the field arithmetic of both major proving stacks
— stwo's M31 through its degree-4 QM31 constraint field, and Plonky3's BabyBear
and KoalaBear with their degree-4 extensions — and lift that exact-value
correctness up through emitted in-place CUDA kernels for the NTT butterfly (both
directions), bit-reversal, scale, and FRI fold, plus the linear layers of a
Poseidon2 round. The emitted kernels are proved *correct* yet benchmark at
hand-tuned speed (within 0.1 % of a Mersenne-fold implementation at ~88 % of the
RTX 5090's memory roofline) — verification is free in the regime that matters.
Reaching in-place swaps/permutations required (and yielded) a small fix to the
compiler's conditional-array-write encoding, which we describe.

## 1. Introduction

Starknet and the broader Cairo ecosystem settle real value on proofs computed by
increasingly heterogeneous, increasingly *accelerated* provers — CPU SIMD, CUDA,
and FPGA backends that re-implement the same field, curve, and hash primitives
for speed. Every such re-implementation is a place where a miscompiled carry, a
mishandled non-canonical representative, or an off-by-one in a Montgomery
reduction silently produces a *valid-looking but wrong* proof. The primitives
are small; the cost of a subtle bug in them is systemic. This is precisely the
setting in which machine-checked reference implementations earn their keep:
not because the algorithms are unknown, but because at this blast radius "the
tests pass" is not an adequate correctness argument.

We target this gap with **Forge**. Forge is a refinement-typed language: a
function may carry `requires`/`ensures` contracts and inline `assert`s over a
predicate logic, and the type-checker emits a proof obligation for every
contract, assertion, call-site precondition, and memory-safety/UB side condition.
Obligations are discharged by Z3, with a small Tier-2/Tier-3 guided/manual
fallback for the rare goal Z3 cannot close directly. Proved programs erase to
C99 (the proofs are compile-time only), giving a verified-to-C pipeline with a
codegen backend also targeting GPU C.

Applying Forge to the Stark stack forces the hard question of any
SMT-backed verifier at scale: **what do you do when the natural obligation does
not terminate?** A direct 248-round elliptic-curve scalar multiplication, asked
as one query, times out at 3000 s. A Montgomery reduction stated as a single
`(result · R) % P == input % P` obligation over 8×64-bit limbs is hopeless for a
solver with no native bignum theory. The bulk of this paper is the set of
structural techniques that turn such goals into thousands of *local, cheap,
terminating* obligations without weakening the end-to-end specification.

**Contributions.**
1. A complete, machine-checked Stark-prime crypto stack (field → curve →
   Pedersen → Poseidon → ECDSA) in a refinement-typed language, emitting
   verified C99 (§3, §4).
2. Four reusable scaling techniques — per-limb projection, witness cascade,
   chunked induction, and the mechanical modulus mirror — with the empirical
   solver-behaviour observations that motivated each (§4).
3. A candid TCB: 39 enumerated audit assumptions, classified, justified, and
   each given a concrete discharge path, so the artifact's trust surface is a
   *checklist*, not a vibe (§5).
4. Engineering that makes the verification practical to *re-run*: the 5,302
   obligations are mutually independent and now discharge across all cores via a
   bounded Z3 worker pool, turning a ~35-minute serial proof into ~100 s (§6).

## 2. Background: Forge

Forge is a refinement-typed language with an SMT proof back end and a C/GPU code
generator. Salient points for this paper:

- **Predicate logic over machine integers.** Contracts and assertions are
  written in a predicate language with `u32`/`u64`/`u256` (and a bignum integer
  "value" view) operators. Arithmetic obligations are discharged in Z3's
  unbounded-integer (`Int`) mode by default; a `#[checked]` attribute opts a
  function into bit-precise overflow obligations discharged in bit-vector
  (`QF_BV`) mode. (Wrapping is the default, as the field-arithmetic corpus
  requires modular semantics.)
- **Three-tier discharge.** Tier 1 is direct Z3; Tier 2 supplies solver hints
  (e.g. nlsat→NIA fallback for goals that are theorems over ℤ but not ℝ); Tier 3
  accepts a user-supplied structural proof term checked by a small trusted
  kernel. The Stark stack is essentially all Tier 1.
- **Erasure to C99.** Proofs are compile-time. `forge build` emits C99 (or
  `forge cuda` emits GPU C). The emitted code is the deployable artifact; the
  proof is the warrant.
- **An assume audit log.** Any fact asserted without mechanical proof is recorded
  as a tagged `assume` with source location and serialized predicate, inspectable
  via `forge audit`. This is the mechanism by which the TCB is made explicit
  (§5).

## 3. The verified stack

The artifact builds bottom-up; each layer's `ensures` is exactly what the next
layer's `requires` consumes.

**Field arithmetic over `P` (Montgomery form).** Carry/borrow helpers with
equational ensures; full schoolbook 8×8 multiplication proven equal to the
257-bit integer product; CIOS Montgomery reduction proven to satisfy
`(result · R) % P == input % P`; and `add`, `sub`, `mul`, `sqr`, `to_mont`,
`from_mont`, `inv` each carrying their modular-correctness contract. The
keystone is `felt252_mul`: `(result · R) % P == (a · b) % P`.

**Elliptic-curve operations.** For `y² = x³ + α·x + β (mod P)`, the operations
`ec_double`, `ec_add`, `ec_neg`, `ec_sub` each preserve the curve predicate
`curve(x,y) := (y²·R) % P == (x³ + x·R² + β·R³) % P` (Montgomery-form integer
values).

**Pedersen hash (byte-equivalent).** Eight phases from the atomic
double-and-add round `pedersen_step` up to `pedersen_full`, the published Stark
Pedersen of two field elements, with `curve(.)` preserved through every layer
and the canonical result recovered via the shift-point trick.

**Poseidon hash (full 91-round Hades).** `hades_permutation_full` runs the
canonical 4-full / 83-partial / 4-full Hades permutation with 273
SHA-256-derived round constants matching Cairo's `poseidon_utils.py`.

**ECDSA verification.** `ecdsa_verify` performs `s⁻¹ mod n`, forms
`u₁=h·s⁻¹`, `u₂=r·s⁻¹`, computes `Q=[u₁]G+[u₂]·pk` via the verified canonical
scalar multiplication, and compares `Q.x mod n` to `r`. This consumes a full
mod-`n` arithmetic stack mirrored from mod-`P` (§4).

## 4. Scaling techniques

### 4.1 Per-limb projection

A multi-precision result is specified not by one opaque obligation over the whole
bignum but by a family of *per-limb projection* lemmas (e.g. `mont_iter_K_limb_J`
for iteration `K`, limb `J`), plus a bigint-reconstruction lemma that ties the
limbs back to the integer value (`Σ_k result.k · Bᵏ == …`). Each projection is a
small, linear, terminating query; the reconstruction is the only place the solver
sees the full width, and it sees it as a single linear identity over already-
established per-limb facts.

### 4.2 Witness cascade

Montgomery reduction's correctness rests on an inductive invariant
("`state_int == input + witness·P`") that must be threaded across 8 iterations.
We materialize the witness explicitly and chain it through helper lemmas
(`pre_cs_after_K`, K=0..7), each of which discharges using only the previous
link's `ensures`. The cascade converts a single intractable inductive goal into
eight local implications.

### 4.3 Chunked induction (function-call boundaries as the escape hatch)

A 256-round scalar multiplication asked monolithically does not terminate. The
fix is structural: verify a 32-round helper *once*, then chain eight calls. Each
call-site precondition discharges *locally* — the prior call's `ensures` matches
the next call's `requires` by direct substitution — at ≈30 s. The 91-round Hades
permutation chains 91 calls the same way. The general principle: **a verified
function boundary is a place where the solver's context resets to a small,
explicit interface**, which is exactly what an SMT back end needs to stay inside
its terminating envelope. This is the single most important technique in the
artifact.

### 4.4 Mechanical modulus mirror

ECDSA needs arithmetic modulo the curve order `n ≠ P`. Rather than re-prove the
Montgomery stack by hand, we generate the entire mod-`n` layer — 161 functions —
by structural substitution from the proven mod-`P` infrastructure
(`STARK_P_LIMB → STARK_N_LIMB`, helper/function renamings). Because the
predicates are structurally identical and differ only in the modulus constant,
the proof structure, the audit-assume shape, and the discharge cost all carry
over. This is a concrete, at-scale demonstration that *duplicated-modulus*
verification can be mechanical rather than re-argued.

## 5. Trusted computing base

For a cryptographic artifact the TCB *is* the headline. Forge's trusted base is
(a) the type-checker/obligation generator, (b) Z3 and the predicate→SMTLIB
encoding, (c) the C codegen, and (d) the explicit `assume`s. We enumerate (d) in
full: **39 audit assumptions**, every one a named analytic fact.

| Class | Count | Examples / justification |
|---|---|---|
| Montgomery analysis (mod-P + mod-n) | 24 | Per-iteration limb-zero invariants; post-reduction bound `< 2P`/`< 2n` (standard CIOS result, Koç/Acar/Kaliski 1996); cap bound; modular-bridge form. |
| Fermat inverse (over P, over n) | 2 | `(result·a) % m == R² % m` for the `a^(m-2)` square-and-multiply chains. Z3 lacks an exponentiation theory; the chain itself is mechanical. |
| EC group law | 3 | Curve-equation preservation for `ec_double`/`ec_add`/`ec_neg`. The slope-formula polynomial identities — *why* EC groups exist — sit outside Z3's nonlinear auto-discharge envelope. |
| Published constants on-curve | 7 | The 5 Pedersen generators, `2²⁵⁶·SHIFT`, and `G`: each verified on-curve at build time and declared so. |
| ECDSA chain | 2 | Caller's pubkey-on-curve precondition; the final boolean comparison. |

Each assumption carries a documented discharge path (§ "research arcs" in the
artifact). For example, the Fermat inverses become mechanical given a
definition-unfolding tactic for recursive predicate functions (gated on an
explicit `@@reveal`), or ~449 step-matching asserts; the EC group law becomes
mechanical via a guided ~50–100-assert slope-substitution chain per operation.
None of the 39 is load-bearing in a way we cannot point at, and the trend is
toward shrinking the list (the per-limb if-select assumption on `pedersen_step`
was already discharged via tuple-typed `if`-`else`). We argue this candor is the
right standard for verified-crypto claims: a TCB you can enumerate and attack is
worth more than an unstated one.

## 6. Reproducibility and proof-time engineering

The whole-stack proof is 5,302 obligations. Crucially, they are **mutually
independent**: each is discharged against a context snapshotted before the
discharge pass (lemmas and assumptions are registered during type-checking,
*before* obligations are attempted), so there is no inter-obligation data
dependence. We exploit this with a bounded pool of Z3 worker threads inside a
single `forge build`: because discharge is subprocess-bound, the language runtime
lock is released during the blocking wait on each Z3 child, so the solver
processes run genuinely in parallel while all in-process state stays serialized
and race-free. Output is folded back in obligation order, so the proof log is
**byte-identical to the serial run** — which we verified across the entire
1,164-demo tracked corpus (zero divergences) and on the heaviest kernels
individually.

The payoff is measured, not projected. On a 24-core host the full felt252 stack
discharges its 5,302 obligations in **100.6 s** wall-clock. The speedup is
governed by the *slowest single obligation* (parallel wall-clock cannot beat the
longest Z3 query, here bounded by the 60 s per-obligation cap), so it is largest
on count-bound proofs: a fused-Poseidon2 field-arithmetic kernel drops from
549 s to 61 s (9.0×), and small kernels see ~10× (a 161-obligation Poseidon2
permutation, 2.20 s → 0.21 s). This turns the whole-stack proof from tens of
minutes into ~100 s — making the artifact something a reviewer or CI can re-run,
not just admire. `FORGE_JOBS=1` recovers the original serial path verbatim.

## 7. Second case study: verified accelerated prover kernels

The same language and techniques transfer from the crypto primitives to the
*hot loop* of a STARK prover — the field, NTT, FRI, and hash kernels that get
hand-ported to GPUs for speed, and where a silent bug (an out-of-bounds column
access, a field element escaping its canonical range, a mis-computed butterfly)
yields a valid-looking but wrong proof.

**Both field families, base through constraint field.** We functionally verify
(exact field value, not merely canonical range) the arithmetic of both major
proving stacks: stwo's **M31** base field, its degree-2 **CM31** complex
extension, and its degree-4 **QM31** constraint field (the field its AIR
constraints live in); and Plonky3's **BabyBear** and **KoalaBear** with their
degree-4 extensions. The base-field operations discharge directly in Z3's
unbounded-integer mode; the extension multiplies use a *P²-padding* trick
(`P² ≡ 0 (mod P)` keeps signed intermediates non-negative) plus one modular-fold
assertion per output component to collapse the nested reductions Z3 will not fold
unaided.

**Up to the emitted kernel.** On top of the verified scalar field ops we verify
the *array post-state* of real in-place GPU kernels: the Cooley-Tukey NTT
butterfly (forward and Gentleman-Sande inverse), the bit-reversal permutation,
the ÷N scale, and the FRI low-degree-test fold (over M31 and CM31) — each proved
to compute the mathematically correct transform, touch only its intended slots
(a locality frame), and preserve range, then emitted as `__global__` CUDA via
`forge cuda`. This uses three composable idioms: the thread index as an explicit
parameter (the SPMD proof model), `old(span[i])` pre-state references, and the
verified scalar primitives. The Poseidon2 round's linear layers (add-round-
constant and the width-3 MDS diffusion) are likewise functionally verified.

**A compiler fix.** Verifying an in-place *swap* inside a conditional exposed a
bug in the compiler's conditional-array-write encoding: a `let`-bound array read
(`let tmp = data[i]`) was re-read from the *post-first-write* array rather than
its bind-time snapshot, so a subsequent `data[j] = tmp` stored the wrong value.
The fix freezes such reads to a stable alias pinned to the block-entry array;
it is 56 lines and passes the full regression suite (1,172 demos, zero new
failures). This is the verification-driven-development loop in miniature: a
provably-wrong proof obligation localized a real soundness-relevant bug in the
toolchain.

**Verified *and* fast.** Because the field reduction is kept as `% P` for
provability (not a branchless Mersenne fold), one might expect a speed penalty.
There is essentially none: benchmarked on an RTX 5090, the emitted NTT butterfly
and FRI fold are within **0.1 %** of a hand-optimized Mersenne-fold kernel at
VRAM-bound sizes, both saturating memory at **~1,560 GB/s (~88 % of roofline)**,
with byte-identical results. The `%`-for-provability compute hides completely
behind memory bandwidth; the only measurable cost (~4 %) appears solely in the
L2-resident/compute-bound regime. The proved-correct kernel is not a research
toy — it runs at hand-tuned speed on real hardware.

**Honest limits.** Two nonlinear goals resist automated discharge and stay
range-verified with a documented audit-assume, both Fermat-class: the modular
inverse `a^(P-2)` (§5) and the Poseidon2 S-box `x⁵ mod P` (which fails even at a
300 s per-obligation budget). The pattern is consistent: *linear* prover-kernel
layers reach full functional correctness; *high-degree nonlinear* ones (inverse,
S-box) reach range plus a named assumption.

## 8. Related work

The artifact sits alongside Fiat-Cryptography (synthesized, proven field
arithmetic), HACL\*/EverCrypt and Vale (verified crypto in F\*/Dafny-style
tooling), and hax (Rust-to-proof extraction). Our point of difference is the
*combination*: an SMT-discharged refinement type system applied end-to-end from
field arithmetic up through a full hash and signature stack over a specific
zk-relevant prime, with the scaling techniques of §4 as the means of staying
inside the solver's terminating regime, and with C/GPU codegen as the
deliverable. The mechanical modulus mirror and the chunked-induction discipline
are, we believe, transferable to any SMT-backed verifier meeting the same
non-termination wall.

## 9. Limitations and future work

The open research arcs are the natural next steps: canonical-form (`result < P`)
propagation through `mul`/`sqr`/`inv` (blocked by a Z3 proof-tactic instability
when the stronger `ensures` enters context — an empirical restructuring problem,
not a soundness one); mechanization of the Fermat and EC-group-law assumptions
(both with concrete, costed paths above); a felt-`P`→felt-`n` canonical bridge to
discharge the final ECDSA comparison; and a Solinas-folding alternative to
Montgomery for the Stark prime. Each shrinks the TCB by a named, enumerated
amount.

## 10. Conclusion

Verified cryptography at the scale that matters for zk-rollups is gated less by
the difficulty of any individual proof than by the engineering of *staying inside
an automated solver's terminating envelope while specifying the real thing*. The
Stark stack presented here is, at 5,302 discharged obligations over 22k lines,
evidence that a refinement-typed, SMT-discharged language can reach a full
field→curve→hash→signature stack, emit deployable C, and — through per-limb
projection, witness cascades, chunked induction, and a mechanical modulus mirror
— do so with a trusted base small enough to print on one page.

The second case study shows the same approach reaching the *other* half of a
trustless-ZK system: the accelerated prover kernels. There the deliverable is not
only a proof but an emitted, functionally-correct GPU kernel that runs at
hand-tuned speed — verification and performance are not in tension when the work
is memory-bound. And the clean division we observe — linear layers reach full
functional correctness, high-degree nonlinear ones (field inverse, S-box) reach
range plus a named audit-assume — is itself a useful map of where an
SMT-discharged refinement type system can and cannot yet go for zero-knowledge
proving. Together the two studies argue that a single such language can specify
and verify both the cryptography a rollup trusts and the kernels that compute its
proofs, keeping the trusted base enumerable at each step.

---

### Artifact

```
forge build demos/std/felt252.fg     # 5,302 SMT obligations, 39 audit assumes
forge audit demos/std/felt252.c      # enumerate the trusted assumptions
FORGE_JOBS=24 forge build demos/std/felt252.fg   # parallel discharge: ~100 s (§6)
```
