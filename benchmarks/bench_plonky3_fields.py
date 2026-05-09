#!/usr/bin/env python3
"""bench_runner.py -- micro-benchmark FORGE-emitted field-multiplication kernels.

Compares baby_bear / koala_bear / m31 element-wise multiply throughput on the GPU.

Usage:
    python3 bench_runner.py [--n 16777216] [--runs 100] [--warmup 10]
"""
import argparse
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import numpy as np

try:
    import pycuda.driver as cuda
    import pycuda.autoinit  # noqa: F401
    from pycuda.compiler import SourceModule
except ImportError:
    print("ERROR: pycuda not installed. Try: pip install pycuda", file=sys.stderr)
    sys.exit(1)


FORGE_DIR = Path(os.environ.get("FORGE_DIR", "/home/garrick/forge"))

BENCHES = [
    {
        "name": "BabyBear mul",
        "cu": FORGE_DIR / "demos" / "2001_bench_baby_bear_mul.cu",
        "kernel": "baby_bear_mul_kernel",
        "p": 2013265921,
    },
    {
        "name": "KoalaBear mul",
        "cu": FORGE_DIR / "demos" / "2002_bench_koala_bear_mul.cu",
        "kernel": "koala_bear_mul_kernel",
        "p": 2130706433,
    },
    {
        "name": "M31 mul (baseline)",
        "cu": FORGE_DIR / "demos" / "2003_bench_m31_mul.cu",
        "kernel": "m31_mul_kernel",
        "p": 2147483647,
    },
]


def patch_cu_for_pycuda(src: Path) -> str:
    """FORGE-emitted .cu uses host C99 conventions; we need a __global__ wrapper.

    Strategy: read the FORGE source, find the kernel function, prepend
    `__global__` and `extern "C"`, leave the rest alone.
    """
    text = src.read_text()
    # Insert extern "C" __global__ just before the kernel function body.
    # FORGE emits e.g. `void baby_bear_mul_kernel(...)` — patch to
    # `extern "C" __global__ void baby_bear_mul_kernel(...)`.
    out_lines = []
    for line in text.splitlines():
        if line.startswith("void ") and "_kernel(" in line:
            line = 'extern "C" __global__ ' + line
        out_lines.append(line)
    return "\n".join(out_lines)


def run_bench(bench: dict, n: int, runs: int, warmup: int) -> dict:
    cu_src = patch_cu_for_pycuda(bench["cu"])

    # Substitute span<T> uses with raw pointer + length pairs already done by FORGE
    # in its emitted C. We can compile the patched source directly.
    mod = SourceModule(cu_src, no_extern_c=True, options=["-O3", "-arch=sm_120"])
    kernel = mod.get_function(bench["kernel"])

    # Allocate inputs/outputs.
    rng = np.random.default_rng(seed=42)
    a_h = rng.integers(0, bench["p"], size=n, dtype=np.uint32)
    b_h = rng.integers(0, bench["p"], size=n, dtype=np.uint32)
    out_h = np.zeros(n, dtype=np.uint32)
    a_d = cuda.mem_alloc(a_h.nbytes)
    b_d = cuda.mem_alloc(b_h.nbytes)
    out_d = cuda.mem_alloc(out_h.nbytes)
    cuda.memcpy_htod(a_d, a_h)
    cuda.memcpy_htod(b_d, b_h)

    # Span layout: FORGE emits span as (ptr, len) tuple in the kernel signature.
    # Specifically FORGE uses `forge_span_t { uint32_t* ptr; uint64_t len; }`
    # or similar. Inspect the .cu to confirm. For pycuda we pass them as ints.
    # Use launch with kwargs based on the FORGE-emitted signature.

    # The simplest path: pack (ptr, len) into a single struct via numpy.
    # Determined by inspecting the .cu — we pass pointer-and-length as
    # consecutive args.
    n_u64 = np.uint64(n)
    threads_per_block = 256
    blocks = (n + threads_per_block - 1) // threads_per_block

    # Warmup runs.
    for _ in range(warmup):
        kernel(out_d, n_u64, a_d, n_u64, b_d, n_u64, n_u64,
               block=(threads_per_block, 1, 1), grid=(blocks, 1))
    cuda.Context.synchronize()

    # Timed runs.
    start_evt = cuda.Event()
    end_evt = cuda.Event()
    times = []
    for _ in range(runs):
        start_evt.record()
        kernel(out_d, n_u64, a_d, n_u64, b_d, n_u64, n_u64,
               block=(threads_per_block, 1, 1), grid=(blocks, 1))
        end_evt.record()
        end_evt.synchronize()
        times.append(start_evt.time_till(end_evt))  # ms

    cuda.memcpy_dtoh(out_h, out_d)

    times = sorted(times)
    median_ms = times[runs // 2]
    min_ms = times[0]
    throughput_mops = n / (median_ms / 1000.0) / 1e6

    return {
        "name": bench["name"],
        "n": n,
        "runs": runs,
        "median_ms": median_ms,
        "min_ms": min_ms,
        "mops_per_sec": throughput_mops,
        "first_out": int(out_h[0]),
        "last_out": int(out_h[-1]),
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=16777216, help="elements (default 16M)")
    parser.add_argument("--runs", type=int, default=100)
    parser.add_argument("--warmup", type=int, default=10)
    args = parser.parse_args()

    print(f"FORGE-emitted field-mul micro-bench")
    print(f"  N = {args.n:,}, runs = {args.runs}, warmup = {args.warmup}")
    print()
    print(f"{'Kernel':<22} {'median(ms)':>12} {'min(ms)':>10} {'Mops/s':>12}")
    print("-" * 60)

    results = []
    for bench in BENCHES:
        if not bench["cu"].exists():
            print(f"  [skip] {bench['name']}: {bench['cu']} not found")
            continue
        try:
            r = run_bench(bench, args.n, args.runs, args.warmup)
            print(f"{r['name']:<22} {r['median_ms']:>12.4f} {r['min_ms']:>10.4f} {r['mops_per_sec']:>12.1f}")
            results.append(r)
        except Exception as e:
            print(f"  [fail] {bench['name']}: {e}")

    print()
    if len(results) >= 2:
        m31 = next((r for r in results if "M31" in r["name"]), None)
        if m31:
            print("Relative throughput (M31 = 1.00x baseline):")
            for r in results:
                ratio = r["mops_per_sec"] / m31["mops_per_sec"]
                print(f"  {r['name']:<22} {ratio:.3f}x")


if __name__ == "__main__":
    main()
