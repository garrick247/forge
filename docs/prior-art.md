# Prior art & novelty positioning

A pressure-test of the novelty claim behind the verified prover-kernel work
(companion to [verified-stark-crypto.md](verified-stark-crypto.md) and
[verified-prover-kernels.md](verified-prover-kernels.md)). Based on a multi-source
literature sweep (20 primary sources, 25 claims adversarially verified, 0
refuted; 2026-07). Written to be honest about what is *not* novel, so the narrow
claim that *is* novel survives scrutiny.

## The claim under test

A single SMT-discharged, refinement-typed language that:
1. verifies STARK-friendly finite fields **and their extension fields** to *exact
   values* (M31 → QM31 degree-4; BabyBear/KoalaBear + degree-4 extensions);
2. verifies STARK **prover kernels** — NTT/iNTT butterflies, FRI fold, bit-reversal,
   Poseidon2 linear layers — to functional correctness;
3. **emits them as CUDA** GPU kernels; and
4. shows those verified kernels run at **hand-tuned speed** (memory-bandwidth-bound,
   ~0.1% of a hand-optimized implementation).

## Verdict

**No published work combines even three of the four components.** Each component
has strong standalone prior art; the novelty is entirely the *co-occurrence*, and
concentrates in the two thinnest-prior-art axes: **verified CUDA emission for ZK
field arithmetic** and **verified-and-performance-competitive** GPU kernels.
Tellingly, the field's own leading verification effort — StarkWare's Lean 4
verification of the stwo prover — targets AIR *soundness* and **explicitly
excludes prover implementation and GPU kernels from scope**, i.e. it carves out
precisely the layer this work occupies.

## Closest prior art, by claim component

| Component | Closest prior art | Gap to the claim |
|---|---|---|
| Functionally-verified GPU kernels | **Kuiper** (F\*, dependent types + CSL, PLDI'25 ARRAY); a **Kyoto** SMT-Hoare-logic tool; **ProofWright** (Rocq + VerCors, arXiv:2511.12294) | All generic ML/HPC (matmul, softmax, element-wise stencils); **zero ZK/field content**; none benchmark their verified kernels at hand-tuned speed. All cleanly exceed GPUVerify (race/divergence only). |
| Verified NTT | **Trieu**, "Formally Verified NTT" (Rocq, IACR CiC 2:4, ANSSI); **CryptoLine** NTT for Kyber/NTRU/SABER (AVX2 + Cortex-M4) | CPU/C or asm only; **foundational Coq/Rocq, not SMT-refinement**; lattice-PQC moduli (q=3329, q=8380417), **not** M31/BabyBear/Goldilocks; **zero GPU/CUDA/SIMT**. |
| Verified STARK-field arithmetic | **LambdaClass TRZK** (Lean 4 e-graph optimizing compiler) — *single closest work*; **CompPoly** (Verified-zkEVM, Lean, poly ops over BabyBear/Goldilocks + extensions) | TRZK: only BabyBear **add/sub/mul**, emits **Rust not CUDA**, explicitly *defers* M31, extension fields, inverse, NTT, ZK primitives. CompPoly: Lean theorem-proving (not SMT-refinement), **no GPU**. |
| Verified field arithmetic (general) | **Fiat-Cryptography** (Coq, IEEE S&P'19; in BoringSSL/Chrome) | 80 **ECC prime** moduli, straight-line **C** (leaves isel/regalloc to a C compiler), **not** small/STARK fields, **not** SMT-refinement. |
| ZK-company / foundation verification | **StarkWare** stwo AIR soundness (Lean 4, arXiv:2606.04311); **Veridise Zequal** (Circom under-constraint, CAV'25); **Succinct** SP1-in-Lean; **Nethermind** CertiPlonk | All **circuit/arithmetization/protocol soundness** — a different layer from prover compute kernels. StarkWare's soundness theorem lists prover/GPU code as *assumed-correct hypotheses*. |
| Verified + performant GPU | **OptiGPU/OptiTrust** (proof-preserving GPU transformations, arXiv:2605.13864) | Not ZK/field; the only near-precedent for "verify AND emit fast GPU," but generic HPC. |

## The defensible narrow claim

> A single SMT-refinement pipeline that verifies STARK-friendly **base and
> extension** fields (M31→QM31, BabyBear) to exact values, verifies the prover
> kernels (NTT/FRI/Poseidon2 diffusion) to functional correctness, **emits CUDA**,
> and demonstrates **bandwidth-bound / hand-tuned parity** — the conjunction of all
> four in one toolchain.

Lead with the two unique axes (verified CUDA for ZK field arithmetic;
verified-at-roofline). Cite StarkWare's explicit scope-exclusion as evidence the
gap is *recognized*. Position TRZK/Fiat-Crypto as the CPU/base-field precursors,
not competitors. Do **not** claim any single component is a first.

## Risks / watch-items

- **Co-occurrence novelty is fragile** — one 2025-26 paper combining 3–4 components
  collapses the claim; this is a fast-moving area.
- **TRZK is the one to watch** — actively developed; a low-reliability search hit
  claimed newer versions added Goldilocks + NTT, but two authoritative reads of the
  current `main` README **contradicted** it (unverified). If TRZK ships verified
  NTT across fields it becomes materially closer (still Rust/CPU, not GPU).
- **Unpublished industry work** — Ingonyama, Irreducible/Binius, Risc Zero,
  Succinct, =nil; could have internal verified-prover efforts not in public sources.
- Several key sources are very recent preprints (not yet peer-reviewed).

## Sources (primary)

- Kuiper — pldi25.sigplan.org/details/ARRAY-2025-papers/6/Kuiper-verified-and-efficient-GPU-programming
- Kyoto GPU functional correctness — fos.kuis.kyoto-u.ac.jp/~kozima/paper/auto-verif-gpu.pdf
- ProofWright — arXiv:2511.12294
- Trieu, Formally Verified NTT — cic.iacr.org/p/2/4/1
- CryptoLine NTT — tches.iacr.org (TCHES 2022)
- LambdaClass TRZK — github.com/lambdaclass/truth_research_zk
- CompPoly — github.com/Verified-zkEVM/CompPoly
- Fiat-Cryptography — github.com/mit-plv/fiat-crypto ; IEEE S&P 2019
- StarkWare stwo AIR soundness — arXiv:2606.04311 ; github.com/starkware-libs/formal-proofs
- Veridise Zequal — eprint.iacr.org/2025/916
- BitModEq (Lean BV/FF) — arXiv:2605.15163
- OptiGPU/OptiTrust — arXiv:2605.13864
- Succinct SP1-in-Lean — blog.succinct.xyz/formal-verification-of-sp1-with-lean
- Nethermind CertiPlonk — nethermind.io/blog/formally-verifying-zero-knowledge-circuits-introducing-certiplonk
