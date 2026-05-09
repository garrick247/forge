# Fused BB-16 Poseidon2 perm — RTX 5090 vs Plonky3 reference

**Byte-identical to Plonky3.** Verified against the published test vector in `Plonky3/baby-bear/src/poseidon2.rs::test_default_babybear_poseidon2_width_16` — all 16 output elements match `default_babybear_poseidon2_16(input)`.

## Throughput sweep (RTX 5090, sm_120, 256 threads/block)

| N (perms) | Median (ms) | Min (ms) | M-perms/sec |
|---|---|---|---|
| 1,024 | 0.0297 | 0.0291 | 34.5 |
| 8,192 | 0.0314 | 0.0301 | 261 |
| 65,536 | 0.0499 | 0.0485 | 1,314 |
| 262,144 | 0.1504 | 0.1484 | 1,743 |
| **1,048,576** | **0.5296** | **0.5217** | **1,980** |
| 4,194,304 | 2.1575 | 2.0146 | 1,944 |
| 16,777,216 | 8.6839 | 8.1076 | 1,932 |

Plateau at ~1.93 G-perms/sec from N=1M onward. Compute-bound (memory traffic at peak: 253 GB/sec — only 14% of HBM3's 1.79 TB/sec ceiling).

## Plonky3 reference (cargo bench, single-thread, AVX2 packed 8-wide)

Hardware: Intel Core Ultra 9 285K (Arrow Lake — no AVX-512), 24 threads.

| Bench | ns/iter | ns/perm | M-perms/sec |
|---|---|---|---|
| BB-16, AVX2-packed | 670 | 83.8 | 11.94 |

24-thread perfect-scaling extrapolation: ~287 M-perms/sec.

## The headline

| Configuration | M-perms/sec | vs Plonky3 single-thread |
|---|---|---|
| Plonky3 single-thread CPU AVX2 (285K) | 11.94 | 1× |
| Plonky3 24-thread perfect-scaling extrapolation | 287 | 24× |
| **Fused GPU kernel (this work, RTX 5090)** | **1,980** | **166×** |

The GPU fused kernel beats a single CPU thread by **166×**, and beats a perfect-scaling 24-thread CPU by **~6.9×**. Real multi-thread CPU never hits perfect scaling (memory bandwidth, NUMA, etc.), so the practical GPU advantage is larger than 6.9×.

## Why it's faster than my earlier projection

The chunk-step bench (`benchmarks/bench_chunk_step`) projected ~275 M-perms/sec. The fused kernel achieves 1,980 — **7.2× higher**. Two reasons:

1. **No HBM round-trip per chunk.** Chunk-step paid 64 B of HBM traffic per chunk and was bandwidth-pinned at N≥4M. Fused holds 16 felts in registers across all 22 layers; only one 64 B read + 64 B write per perm at the boundary.
2. **Plonky3's M_4 matrix uses only mul-by-{2,3} coefficients, which become add-instructions** (`bb_double`, `bb_add(2x, x)`). My earlier per-perm mul estimate (~1400) included these as muls; the actual per-perm mul count is ~746 (8 ext × 64 sbox-mul + 13 partial × 18 diag-mul). At 1,980 G-perms/sec × 746 mul/perm ≈ **1.48 T mul/sec** — within the 5090's u32-imul-throughput envelope, suggesting the kernel is at or near the chip's compute ceiling for this workload.

## What's in the kernel

- 1 initial linear layer (M_E only)
- 4 initial external rounds: each = 16× ARK + SBOX (x⁷ = 4 muls) + M_E
- 13 partial rounds: each = 1× ARK[0] + SBOX[0] + diagonal mixing M_I = I + Diag(V)
- 4 terminal external rounds: same as initial

Round constants and diagonal V exactly match Plonky3's `BABYBEAR_POSEIDON2_RC_16_*` and `BabyBearInternalLayerParameters::internal_layer_mat_mul`. No approximations, no random RCs — this is the production permutation.

## Verification status

- **Byte-identity vs Plonky3**: confirmed via test vector ✓
- **FORGE/Z3 verification**: not yet — the chained-let-binding form (~700 SSA bindings) hit quadratic SMT-state blow-up in FORGE's current solver pipeline (~2 sec/SMT call growing). Killed at line 236/1412. The chunk-step bench (`demos/2006/2007`) covers the verified path for the round building block; the fused composition is presently CUDA-direct. **Future work**: factor each round into its own `#[device]` function so per-function proof obligations are bounded — this should make the fused permutation FORGE-verifiable.

## Files

- `benchmarks/poseidon2_bb16_fused.cu` — the fused kernel + constant arrays
- `benchmarks/bench_fused_perm.cu` — host harness (correctness check + throughput sweep)
- `benchmarks/bench_fused_perm` — compiled binary
- `tools/gen_fused_perm.py` — kept for future when FORGE-verified version becomes feasible

## Reproducer

```bash
cd /home/garrick/forge
nvcc -O3 -arch=sm_120 \
    benchmarks/bench_fused_perm.cu \
    benchmarks/poseidon2_bb16_fused.cu \
    -o benchmarks/bench_fused_perm
./benchmarks/bench_fused_perm
```

```bash
# Plonky3 reference
cd ~/Plonky3
RUSTFLAGS='-C target-cpu=native' cargo bench -p p3-poseidon2 \
    --bench=poseidon2 -- 'BabyBear' --warm-up-time 1 --measurement-time 3
```
