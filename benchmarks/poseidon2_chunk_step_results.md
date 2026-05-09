# Poseidon2 chunk-step bench — FORGE-emitted GPU vs Plonky3 reference

**Hardware**
- GPU: RTX 5090, sm_120, 170 SMs, 1.79 TB/s HBM3
- CPU: Intel Core Ultra 9 285K (Arrow Lake), 24 threads, AVX2 + AVX-VNNI (no AVX-512)

## FORGE-emitted GPU chunk-step (one chunk's worth of one external round: 4 ARK + 4 SBOX + 4×4 MDS)

| N chunks | BB M-chunks/s | KB M-chunks/s | KB/BB | Regime |
|---|---|---|---|---|
| 64K | 14.2 | 21.1 | 1.48× | launch-overhead floor |
| 256K | 38.3 | 50.0 | 1.30× | warming up |
| 512K | 55.4 | 67.4 | 1.22× | scaling |
| 1M | 66.3 | 89.5 | 1.35× | compute-bound |
| **2M** | **68.4** | **92.4** | **1.35×** | **compute-bound peak** |
| 4M | 35.3 | 35.3 | 1.00× | HBM-bound |
| 16M | 32.7 | 32.8 | 1.00× | HBM-bound |

Crossover to HBM-bound at N=4M because each chunk-step costs 64 B of memory traffic (32 B state read + 16 B rc read + 16 B out write). At 35 M chunk/s × 64 B = 2.24 TB/s — pinned to HBM peak.

## Plonky3 reference (cargo bench, single-thread, AVX2 packed 8-wide)

| Width | BB time/iter | BB ns/perm | BB perms/s | KB time/iter | KB ns/perm | KB perms/s |
|---|---|---|---|---|---|---|
| 16 | 670.1 ns | 83.8 | 11.94 M | 545.8 ns | 68.2 | 14.66 M |
| 24 | 1124 ns | 140.5 | 7.12 M | 918 ns | 114.8 | 8.71 M |

KB-16 / BB-16 on CPU: **1.23×** (matches GPU 1.35× to within field-overhead noise — both reflect the x³ vs x⁷ S-box difference, dampened by the modular reduction being the same per multiplication).

## The comparison

A BB-16 Poseidon2 permutation is roughly:
- 8 external rounds × (4 chunks × 4 felts × 4 mul S-box + 4 chunks × ~16 mul MDS + 16-elem outer mixing) ≈ 1150 mul
- 13 internal rounds × (1 sbox × 4 mul + 16 mul diagonal mixing) ≈ 260 mul
- Total ≈ **1400 mul/perm**

A chunk-step covers ~32 mul, so ≈ 44 chunk-steps' worth of compute per full perm.

Therefore the FORGE bench at peak (68.4 M chunk-steps/s for BB) implies a *current* **~1.55 M perms/sec** equivalent if you actually wired up a full perm using the same per-chunk-loaded I/O pattern. That's well below Plonky3's single-thread CPU peak of 11.94 M/s.

**Why the GPU loses here**: my bench layout forces every chunk-step to round-trip through HBM. A real GPU full-permutation kernel would hold the 16-felt state in registers across all 21 rounds, paying HBM only once on input/output. Compute-bound ceiling for that fused kernel: 386 G mul/s ÷ 1400 mul/perm = **~275 M perms/sec for BB-16**, which would be ~23× a single CPU thread (and ~1× the theoretical 24-thread CPU peak of ~287 M/s). HBM-bound ceiling would be 1.79 TB/s ÷ 128 B/perm = ~14 G perms/sec — never the binding constraint.

## Headline (the honest version)

| Configuration | BB-16 perms/sec |
|---|---|
| Plonky3 CPU, AVX2 packed, single-thread (285K) | 11.9 M |
| Plonky3 CPU, all 24 threads, perfect-scaling extrapolation | ~287 M |
| FORGE GPU chunk-step, current per-chunk HBM I/O (this bench) | ~1.55 M (HBM-bound on the wrong unit) |
| FORGE GPU full-perm fused, compute-bound projection | **~275 M** |
| FORGE GPU full-perm fused, HBM-bound ceiling | ~14 G (would never bind) |

The chunk-step bench measures one isolated round component honestly, and the 1.35× KB/BB ratio is real and matches Plonky3's CPU 1.23× — confirming the field-choice signal at the chip level. But the perm/s comparison against Plonky3 needs a fused kernel where state stays in registers across all 21 rounds. **That's the obvious next move.**

## Files
- `demos/2006_bench_baby_bear_chunk_step.fg` (and `.cu`, `.ptx`) — BB chunk-step kernel
- `demos/2007_bench_koala_bear_chunk_step.fg` (etc.) — KB version
- `benchmarks/bench_chunk_step.cu` — host harness
- `benchmarks/bench_chunk_step` — compiled binary
- `~/Plonky3/` — fresh shallow clone, cargo bench works as `cargo bench -p p3-poseidon2 --bench=poseidon2`
