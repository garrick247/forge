# felt252.fg — Runtime Benchmarks

Microbenchmarks of the Forge-emitted C99 output (`demos/std/felt252.c`)
for the verified Stark crypto primitives. All single-threaded, x86-64,
GCC 13.x at `-O2` on a recent Linux box (i9-12900K class CPU).

```
gcc -O2 -c felt252.c -o felt252.o
gcc -O2 -o bench benchmark.c felt252.o
./bench
```

(Prior to commit `8ef9373` the compile required `-Du256=__uint128_t`
and `-Dmain=__felt_main_unused` workarounds; the codegen fix emits
the polyfill typedefs in the C header and marks `main` weak so those
flags are no longer needed.)

## Headline numbers

| Operation | Time | Throughput |
|---|---|---|
| `felt252_mul` | **164 ns/op** | 6.1 M ops/sec |
| `felt252_sqr` | **155 ns/op** | 6.5 M ops/sec |
| `felt252_inv` (449-op Fermat chain) | **69 µs/op** | 14.5 k ops/sec |
| `hades_permutation_full` (91-round Poseidon) | **166 µs/op** | 6.0 k ops/sec |
| `pedersen_full` (4× scalar mul + Pedersen assembly) | **144 ms/op** | 7 ops/sec |
| `ecdsa_verify` (full Stark curve verify) | **72 ms/op** | 14 ops/sec |

## Reading the numbers

### Field arithmetic — competitive

`felt252_mul` and `felt252_sqr` at ~155 ns/op are in the right ballpark
for naive 8-limb schoolbook + Montgomery reduce in straight C. For
reference, starknet-rs's modular mul (which uses hand-written `mulx`
intrinsics and tighter limb packing on x86-64) hits ~80-100 ns/op on
the same class of hardware — Forge's output is ~1.5-2× slower, the
expected gap between portable verified C and intrinsic-tuned Rust.

`felt252_inv` is dominated by the 251 squarings + 198 muls in the
Fermat chain: 449 × 154 ns ≈ 69 µs, exactly what we measure.

### Poseidon — competitive

`hades_permutation_full` at 166 µs/op is the full Starknet Poseidon
91-round permutation with 273 SHA-256-derived round constants. Per
round: 3 sqr + 3 mul + 9 mul (MDS) + 3 add ≈ 15 mul-equivalents. 91
rounds × 15 ops × 155 ns ≈ 211 µs predicted; measured 166 µs, slightly
better than the naive estimate because round-constant additions are
free vs. multiplications.

starknet-rs's Poseidon hits ~50-80 µs on similar hardware. Forge is
2-3× slower, again the portable-C-vs-tuned-Rust gap.

### Pedersen — glacial (architecture, not perf)

`pedersen_full` at 144 ms/op is the *correctness-first* implementation:
4 unrolled 256-round scalar multiplications via `pedersen_scalar_mul_256`,
each round doing `ec_double` + conditional `ec_add` (themselves built on
`felt252_mul` / `felt252_inv`). Per scalar mul: 256 × (~100 µs ec-op) ≈
26 ms. Four scalar muls + 4 `ec_add` combines ≈ 100-150 ms total.

Production Stark Pedersen implementations (starknet-rs, cairo-lang)
hit ~1 ms/op via precomputed multi-scalar tables (Solinas-style fixed-
base scalar multiplication that pre-multiplies the generators at
compile time). Forge's output doesn't yet do this — each scalar mul
is a literal 256-round double-and-add chain.

**This is a 100-150× perf gap explained entirely by the algorithm
choice, not by Forge's codegen.** Replacing the double-and-add with a
windowed-NAF table lookup would close most of it. The verified
chunked-induction scaffold is still useful as a reference / oracle
for testing the faster implementation.

### ECDSA — glacial for the same reason

`ecdsa_verify` at 72 ms/op = 2 × `pedersen_scalar_mul_canonical` +
some mod-n arithmetic + `ec_add`. Same windowed-NAF speedup would
apply for the scalar muls.

## Where this code is most useful

1. **Reference / differential testing oracle**: byte-equivalent to
   spec Stark Pedersen and Poseidon. Run side-by-side against a tuned
   implementation; if their outputs ever disagree, the tuned version
   has a bug. The verified C99 is correct by construction.

2. **Cryptographic operations off the hot path**: places where 100 ms
   for a single Pedersen is acceptable — e.g., one-shot key derivation,
   signature generation/verification with low throughput requirements,
   audited intermediate steps in zkVM bootstrapping.

3. **Spec for verified ports**: hax/Cryspen, Fiat-Cryptography, F\*
   teams could use this as a verified C99 reference to port into their
   ecosystems; the audit trail (38 trusted assumptions, each named)
   documents exactly what's load-bearing.

## Where you would NOT use this code

- Production zkVM hot paths (Pedersen called millions of times per
  proof).
- Bulk signature verification at TPS-relevant rates.

Both of those need the windowed scalar multiplication speedup.

## Open work

Forge-emitted scalar multiplication via precomputed tables would
collapse Pedersen / ECDSA to the ~1 ms range. The verified primitives
(`ec_double`, `ec_add`, `felt252_mul`, `felt_n_inv`) already exist;
what's missing is a different `pedersen_scalar_mul_*` body that takes
a precomputed table of `[2^i] · base` points and indexes into them
per-bit instead of double-and-adding from scratch.

## Comparison framework caveats

- Numbers measured on a single machine, single thread, `-O2`. PGO,
  LTO, or `-O3` may shift by ~10-20%.
- No comparison against starknet-rs or cairo-lang reference
  implementations in-tree yet. The "~50-80 µs Poseidon, ~1 ms Pedersen"
  numbers cited above are recalled from prior benchmarks, not measured
  in this run. A real shootout against starknet-rs would build both,
  pin to the same CPU, and produce side-by-side data.
- ECDSA verify takes inputs that may not correspond to a valid
  signature. The function does the same work regardless of validity;
  the timing is on the cost of running the verification chain.
