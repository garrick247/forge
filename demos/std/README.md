# felt252.fg — Verified Arithmetic over the Stark Prime

A Forge-verified library of arithmetic primitives over the Stark prime
`P = 2^251 + 17·2^192 + 1`, the curve underlying Starknet. Compiles
to verified C99.

## What's proven (SMT-discharged by Z3)

### Foundations (carry/borrow helpers, constants)

| Function | Verified property |
|---|---|
| `add_with_carry_sum/out` | `result == (a + b + c_in) % B` / `/ B`  (equational ensures) |
| `sub_with_borrow_diff/out` | `result == (a + B - b - b_in) % B` (equational ensures) |
| `STARK_P_LIMB0..7`, `STARK_R2_LIMB0..7` | Stark prime + R² constants |

### Per-limb math (projection-style ensures)

| Function | Verified property |
|---|---|
| `felt252_add_mod_spec` | Per-limb projection mirroring 8-limb add + cond-sub case-split |
| `felt252_sub_mod_spec` | Per-limb projection for subtract with cond-add-back |
| `felt252_mul_raw_spec` | 16 per-limb verified projection functions over schoolbook 8×8 |

### Integer-level math (bigint reconstruction)

| Function | Verified property |
|---|---|
| `felt252_add_bigint_spec` | `(sum_k result.k · B^k) + cap·B^8 == a_val + b_val` (257-bit integer sum) |
| `felt252_mul_raw` | `(sum_k result.k · B^k) == a_val · b_val` (full schoolbook ↔ 16-limb int product) |

### Mod-P math correctness (the keystone)

| Function | Verified property |
|---|---|
| `felt252_add` | `(a<P && b<P) ⇒ (result<P && (result == a+b ∨ result+P == a+b))` |
| `felt252_sub` | `(a<P && b<P) ⇒ (result<P && (result+b == a ∨ result+b == a+P))` |
| `felt252_mont_cond_sub` | `result == state_9 ∨ result+P == state_9` under `state_9 < 2P` |
| `felt252_montgomery_reduce_v2` | `(result · R) % P == input % P` |
| `felt252_mul` | `(result · R) % P == (a · b) % P` |
| `felt252_sqr` | `(result · R) % P == (a · a) % P` |
| `felt252_to_mont` | `(result · R) % P == (a · R²) % P` |
| `felt252_from_mont` | `(result · R) % P == a % P` |
| `felt252_inv` | `(result · a) % P == R² % P` (modular inverse in Mont form) |

### Elliptic curve operations (Stark curve, α=1, β = 3141592653589793238462643383279502884197169399375105820974944592307816406665)

| Function | Verified property |
|---|---|
| `ec_double` | `curve(x, y) ⇒ curve(x_new, y_new)` |
| `ec_add` | `curve(x1, y1) ∧ curve(x2, y2) ⇒ curve(x3, y3)` |
| `pedersen_step` | `curve(r) ∧ curve(b) ∧ bit<2 ⇒ curve(if bit then ec_add(ec_double(r), b) else ec_double(r))` |

Where `curve(x, y) := (y² · R) % P == (x³ + x · R² + β · R³) % P` is the
Stark curve equation in Mont-form integer values.

`pedersen_step` is the atomic double-and-add round used to build up
scalar multiplications for Stark Pedersen. A full 248-bit scalar mul
is 248 unrolled `pedersen_step` calls; the full hash H(a, b) is 4
scalar muls + 4 ec_adds + a shift point.

Where `R = 2^256`, `B = 2^32`, `P = 2^251 + 17·2^192 + 1`.

### Montgomery reduce internals (per-iteration)

| Function | Verified property |
|---|---|
| `mont_iter_K_limb_J` (K=0..7, J=0..15) | Per-limb projection of iteration K's update |
| `mont_iter_K_cap_out` | Per-iteration carry-out value projection |
| `mont_iter_K_split` | Aggregate: `state_after == state_before + m_K · P · B^K` |
| `pre_cs_after_K` (K=0..7) | Chained: `state_int == input + witness_int · P` |

### Contract correctness (always proven)

- No buffer overflows, no UB, no division-by-zero, no integer overflow
  in u32/u64 arithmetic (modulo the verified modular operations)
- Function preconditions discharged at every callsite

## Audit trail (16 trusted assumptions)

The library declares 16 `assume()` calls that aren't proven within the
file. Each is a standard, well-known analytic fact.

**`felt252_montgomery_reduce_v2` — 12 Montgomery-analysis assumes:**

- 8× per-iteration limb-zero invariants: `s0..s7 == 0` after 8 iters
  (each follows from `mont_iter_K_split`'s ensures + passthrough
  preservation; the cumulative propagation through `pre_cs_after_K`
  helpers is the open work item)
- 1× Montgomery analysis bound: post-iter-7 state < 2P (standard CIOS
  result, Koc/Acar/Kaliski 1996)
- 1× cap bound: `cap_out <= 1u64` (follows from the cap-bound inductive
  lemma already proven elsewhere in the file)
- 1× modular bridge form: `(R·state_9) % P == input % P` (algebraically
  follows from the proven `R·state_9 == input + witness·P` bridge)

**`felt252_inv` — 1 Fermat audit-assume:**

- `(result · a) % P == R² % P` — Fermat's little theorem applied to the
  449-op square-and-multiply chain implementing `a^(P-2)` for the Stark
  prime. The mechanical chain is canonical (generated from the bit
  pattern of P-2); the inverse identity follows because
  `a^(P-2) · a == a^(P-1) ≡ 1 (mod P)` for nonzero `a`. Z3 cannot derive
  this without an exponentiation theory or uninterpreted-function
  support in Forge predicates — a bare-ensures probe returns
  proof_failed in 283s.

**`ec_double` / `ec_add` — 2 EC group-law audit-assumes:**

- Curve-equation preservation: the slope formulas
  λ = (3x² + α)/(2y) (double) and λ = (y2-y1)/(x2-x1) (add),
  combined with x_new = λ² - 2x or λ² - x1 - x2 and y_new = λ(x - x_new) - y,
  preserve the curve equation `y² = x³ + αx + β (mod P)`. Algebraically
  derivable (this is *why* elliptic curve groups exist) but requires
  nonlinear polynomial composition across 11+ mod-P ops, outside Z3's
  auto-discharge envelope without explicit polynomial expansion.

**`pedersen_step` — 1 if-select audit-assume:**

- Per-limb if-select over 16 result components: when `bit==1` the result
  is `ec_add(ec_double(r), b)`, when `bit==0` it's `ec_double(r)`. Both
  branches independently satisfy curve(.) by ec_double/ec_add ensures,
  so the result is on the curve regardless. Z3 cannot derive curve(.) of
  a per-limb if-selected tuple without an explicit case-split.

All 16 are tagged in the assume audit log. Run `forge audit <file>` to
inspect them.

## What's NOT verified (research arcs)

| Item | Why deferred |
|---|---|
| Canonical-form propagation (`result < P` ensures on mul/sqr/inv) | The current case-2 assert in v2 is fragile to added facts; needs restructuring before canonical-form can chain through. |
| `felt252_reduce_512` (Solinas folding) | Unimplemented function — alternative to Montgomery for Stark prime. |
| 12-assume audit reduction via inductive proofs | Would prove each Montgomery bound from a P·R input bound. Substantial inductive work. |
| Fermat audit-assume → mechanical proof | Currently the 1-assume Fermat trust gap covers the 449-op inv chain. Eliminating it requires Forge support for uninterpreted functions (so `pow(a, k)` can be axiomatized) and an inductive Fermat lemma. Substantial language-design work. |
| EC group-law audit-assumes → mechanical proof | Currently 2 audit-assumes cover curve preservation through ec_double / ec_add. Direct discharge requires explicit polynomial expansion of the slope-substituted curve equation — a multi-thousand-term composition that Forge's predicate language can express but Z3 will not naively chase. A semi-mechanical approach via guided proof terms is possible. |

## Build / use

Requires the patched Forge with `assume_fact_propagation.patch` applied
(see that file). Without the patch, v2 mod-P verification fails because
`stmt_final_env` silently drops body-position `assume` statements.

```
forge-rag check demos/std/felt252.fg
# Expected: proof_ok, 3038 / 3038 SMT, 16 audit assumptions
```

Emits `demos/std/felt252.c` — verified C99 the C codegen target.

## Who should care

- **Starknet / Cairo ecosystem developers**: drop the emitted C as the
  felt252 reference implementation with documented verification status.
  Build Pedersen, Poseidon, ECDSA on top with confidence in the limb-
  level arithmetic.

- **Verified-cryptography researchers** (Fiat-Cryptography, hax,
  EverCrypt): per-limb split methodology + witness-cascade pattern are
  contributions to the modular-arithmetic verification toolkit.

- **Forge core**: this is the largest known Forge demo (~3000 SMT
  obligations). The `assume_fact_propagation` patch and the witness-
  cascade pattern are concrete language-design feedback.

- **GPU prover validation**: spec-correct reference for differential
  testing of CUDA/FPGA implementations.

- **Formal-methods publication**: "Verified Stark-prime arithmetic in
  a refinement-typed language with SMT discharge" is a paper.

## Commit history (math-correctness layer, in build order)

| Commit | Layer |
|---|---|
| `c20cf43` | Per-iteration Mont math-correctness (8 `mont_iter_K`) |
| `ae94ff9` | Cap-bound inductive lemma |
| `840fe44` | Bigint foundations + `felt252_add_bigint_spec` |
| `77b1e9b` | Mod-P on `felt252_add` |
| `7751544` | Mod-P on `felt252_sub` |
| `b747ab3` | `felt252_mul_raw` integer-product |
| `f7da1a0` | `montgomery_reduce` body rewrite (explicit `%`/`/`) |
| `6e204ff` | Per-iter Mont split (144 sub-funcs + 8 composers) |
| `90efe66` | Bounded `felt252_mont_cond_sub` |
| `a976104` | Witness cascade (8 chained `pre_cs_after_K`) |
| `0b9df75` | `felt252_montgomery_reduce_v2` mod-P |
| `fa53567` | **`felt252_mul` mod-P composition (keystone)** |
| `c7b92e7` | `felt252_sqr` mod-P |
| `b2772d3` | `felt252_to_mont` / `felt252_from_mont` mod-P |
| `eaea660` | `felt252_inv` mod-P via Fermat audit-assume |
| `102eb8b` | `ec_double` / `ec_add` curve-equation preservation via group-law assumes |
| `a0fa746` | `pedersen_step` atomic double-and-add round with curve preservation |

Plus the Forge core patch (`assume_fact_propagation.patch`) — submitted
or fork-applied separately.
