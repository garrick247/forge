# Forge — Soundness Boundary & Trusted Computing Base

> What "correct by construction" does and does not mean in Forge, stated precisely.
> Forge proves a lot. The value of those proofs depends entirely on knowing what
> is *trusted* versus what is *proven*. This document draws that line.

---

## 1. The Trusted Computing Base (TCB)

A Forge proof guarantees a property *modulo* the correctness of everything below.
When `forge build` reports "all obligations discharged," you are trusting:

| # | Trusted component | Where | Failure mode if buggy |
|---|-------------------|-------|-----------------------|
| 1 | **Lexer + parser** | `lib/lexer`, `lib/parser` | A program is parsed into an AST that doesn't match its surface syntax; proofs then describe a different program than the one written. |
| 2 | **Typecheck to SMT translation** (`pred_to_smtlib`) | `lib/proof/proof_engine.ml` | An obligation or hypothesis is mistranslated into SMT-LIB; Z3 then proves the wrong lemma. The single most safety-critical translation in the system. |
| 3 | **Z3** (external SMT solver) | subprocess | An unsound `unsat`. Rare, but Z3 is trusted wholesale. |
| 4 | **Proof erasure** | `lib/codegen` | Specifications are erased before emission; if erasure changed runtime behaviour, the emitted program would differ from the verified one. |
| 5 | **Code emitter** (C99 / CUDA C / PTX) | `lib/codegen/codegen_c.ml`, `codegen_ptx.ml` | The emitted code does not faithfully implement the verified AST semantics. **Validated by differential testing, not proven** — see section 4. |
| 6 | **Audited escape hatches**: `assume(...)`, `declassify(...)`, manual proof terms | program-level | A false `assume` injects a false fact; everything downstream is then vacuously "provable." Dump them with `forge audit`. |

Forge does **not** have a machine-checked metatheory: there is no proof that the
obligation generator is itself sound or complete with respect to a formal semantics
of the language. The proof *kernel* (Calculus of Constructions, for Tier-3 terms) is
checked structurally; the SMT path (Tiers 1-2) trusts items 2-3 above.

**Bottom line:** Forge eliminates whole classes of bugs (out-of-bounds, the proven
postconditions, termination) *given* a correct front-to-back translation. It is a
very strong testing-replacement and specification tool. It is not a machine-verified
compiler in the CompCert sense, and does not claim to be.

---

## 2. Integer semantics: wrapping by default

Forge emits plain C/CUDA arithmetic. **Fixed-width integer arithmetic wraps**, exactly
as in C — `u64` addition is mod 2^64.

By default, proof obligations for ordinary arithmetic are discharged in **Int mode**
(see section 3), which models integers as *unbounded mathematical integers*. This is
sound for properties that do not depend on wraparound (the overwhelming majority: index
arithmetic on realistic sizes, monotonicity of bounded quantities, etc.), but it means a
postcondition can be *proven in math-integers yet violated at runtime by overflow*.

Concretely, by default Forge will prove:

```forge
fn add(a: u64, b: u64) -> u64 ensures result >= a { a + b }   // PROVES (math integers)
```

even though `a + b` wraps for large `a`. This is a deliberate, documented choice: the
entire field/modular-arithmetic corpus (Montgomery reduction, M31/BabyBear fields,
Poseidon, Blake2s, the felt252 Starknet crypto stack) *relies* on wraparound and would
be unprovable under mandatory overflow checking.

### Opt-in overflow checking: `#[checked]`

Annotate a function `#[checked]` to require that **unsigned** `+`, `-`, `*` cannot
overflow/underflow. Forge emits a no-overflow obligation per operation, discharged in
**BV mode** (bitvectors model wraparound *exactly*):

```forge
#[checked]
fn add(a: u64, b: u64) -> u64 ensures result >= a { a + b }   // REJECTED: cannot prove (a+b) >= a

#[checked]
fn add(a: u64, b: u64) -> u64
    requires a <= 1000u64
    requires b <= 1000u64
    ensures result >= a { a + b }                              // PROVES
```

Obligations emitted under `#[checked]` (unsigned operands only):

| op | obligation | meaning |
|----|------------|---------|
| `a + b` | `(a + b) >= a`  (bvuge) | no unsigned overflow |
| `a - b` | `a >= b` | no unsigned underflow |
| `a * b` | `a == 0` or `(a*b)/a == b` | no unsigned multiply overflow |

**Not yet covered (tracked):** signed-integer overflow (INT_MIN edge cases),
left-shift overflow, and overflow inside `assume`/`ensures` predicate expressions.
Until those land, `#[checked]` is a guarantee about unsigned `+ - *` only. Do not read
it as total overflow freedom.

---

## 3. The Int / BV mode seam

Z3 is driven in one of two theories, selected automatically:

| | **Int mode** (default) | **BV mode** |
|---|---|---|
| Integer model | unbounded mathematical `Int` | exact `(_ BitVec N)`, wraps |
| Triggers | everything by default | goal contains a bitwise op (`& \| ^ << >>`), or a `#[checked]` overflow obligation (forced) |
| Quantifiers | yes (`forall`/`exists`, array theory) | **no** — `QF_BV` is quantifier-free |
| Injected proved lemmas | yes | **no** (lemmas are not asserted in BV mode) |
| Good for | bounds, postconditions, loop invariants, termination | bit-exact reasoning, overflow |

This seam is itself a trust-relevant boundary:

- A goal that mixes **quantified** reasoning with **bit-exact** reasoning cannot be fully
  discharged in either mode — Int mode loses bit-accuracy, BV mode loses the quantifier.
  Split such goals, or prove the bitwise lemma separately.
- Proved lemmas (`by lemma(...)`) are **not** available inside BV-mode goals. A `#[checked]`
  overflow obligation therefore sees only the local hypotheses (preconditions, guards),
  not the global lemma database.
- Mode selection is automatic and must stay automatic; manually forcing the wrong theory
  would be unsound (a BV-mode "proof" of a quantified goal could be vacuous).

---

## 4. Codegen is validated, not proven

The proofs are about the **Forge AST**. Correctness of the *emitter* (AST → C99 / CUDA C /
PTX) is established by **differential testing against nvcc**, not by proof:

- **FB-0** freezes a baseline of 5 reference kernels where Forge-emitted CUDA C matches
  hand-written CUDA at the **SASS level** (identical register and instruction counts).
- The broader corpus is validated by GCC compilation (`-Wall -Wextra -Werror`) and runtime
  execution of emitted C.

This is strong evidence, not a theorem. Five SASS-parity kernels is a sample, not a
universally-quantified guarantee over the emitter. Extending differential coverage (every
emitted kernel diffed against a reference) is the purpose of **FB-1** (see `benchmarks/`).
Treat the emitter as part of the TCB (section 1, item 5).

---

## 5. How to keep your own proofs honest

- Run `forge audit <file.c>` and read every `assume(...)`. Each one is a hole you chose to
  leave. A function with a false or over-strong `assume` can "prove" anything.
- Prefer `requires` (checked at every call site) over `assume` (trusted unconditionally).
- Use `#[checked]` on any unsigned arithmetic whose *result magnitude* matters for safety
  (allocation sizes, byte counts, offsets that are not provably small).
- Remember that a green `forge build` is a statement about the AST. Pair it with the
  differential/runtime tests for the codegen half of the story.

---

*Forge proves what it says it proves. This document exists so that "what it says" is never
larger than "what it does."*
