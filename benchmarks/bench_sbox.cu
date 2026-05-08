// bench_sbox.cu -- Poseidon2 S-box throughput on RTX 5090.
// Compares BabyBear x^7 (4 mul) vs KoalaBear x^3 (2 mul).
// Same memory access pattern (a[i] -> out[i]); the only difference
// is per-element compute. Compute-bound regime should show ~2x ratio.

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <vector>
#include <random>
#include <algorithm>
#include <cuda_runtime.h>

extern __global__ void baby_bear_sbox_kernel(
    uint32_t* __restrict__ out, uint64_t out_len,
    uint32_t* __restrict__ a, uint64_t a_len,
    uint64_t n);
extern __global__ void koala_bear_sbox_kernel(
    uint32_t* __restrict__ out, uint64_t out_len,
    uint32_t* __restrict__ a, uint64_t a_len,
    uint64_t n);

#define CK(call) do {                                                        \
    cudaError_t err = (call);                                                \
    if (err != cudaSuccess) {                                                \
        fprintf(stderr, "CUDA error %s:%d: %s\n",                            \
                __FILE__, __LINE__, cudaGetErrorString(err));                \
        exit(1);                                                             \
    }                                                                        \
} while (0)

struct BenchResult {
    const char* name;
    double median_ms;
    double min_ms;
    double mops_per_sec;
};

typedef void (*KernelPtr)(uint32_t*, uint64_t, uint32_t*, uint64_t, uint64_t);

static BenchResult run_one(const char* name, KernelPtr kernel,
                           uint64_t n, uint32_t prime, int runs, int warmup) {
    std::vector<uint32_t> a_h(n), out_h(n);
    std::mt19937 rng(42);
    for (uint64_t i = 0; i < n; i++) {
        a_h[i] = (uint32_t)(rng() % prime);
    }
    uint32_t *a_d, *out_d;
    CK(cudaMalloc(&a_d, n * sizeof(uint32_t)));
    CK(cudaMalloc(&out_d, n * sizeof(uint32_t)));
    CK(cudaMemcpy(a_d, a_h.data(), n * sizeof(uint32_t), cudaMemcpyHostToDevice));

    int threads = 256;
    int blocks = (int)((n + threads - 1) / threads);

    for (int i = 0; i < warmup; i++) {
        kernel<<<blocks, threads>>>(out_d, n, a_d, n, n);
    }
    CK(cudaDeviceSynchronize());

    std::vector<float> times;
    cudaEvent_t evStart, evStop;
    CK(cudaEventCreate(&evStart));
    CK(cudaEventCreate(&evStop));
    for (int i = 0; i < runs; i++) {
        CK(cudaEventRecord(evStart));
        kernel<<<blocks, threads>>>(out_d, n, a_d, n, n);
        CK(cudaEventRecord(evStop));
        CK(cudaEventSynchronize(evStop));
        float ms;
        CK(cudaEventElapsedTime(&ms, evStart, evStop));
        times.push_back(ms);
    }
    CK(cudaEventDestroy(evStart));
    CK(cudaEventDestroy(evStop));

    std::sort(times.begin(), times.end());
    double median = times[runs / 2];
    double min_ms = times[0];
    double mops = (double)n / (median / 1000.0) / 1e6;

    BenchResult r{ name, median, min_ms, mops };

    CK(cudaFree(a_d));
    CK(cudaFree(out_d));
    return r;
}

int main(int argc, char** argv) {
    uint64_t n = 16777216;
    int runs = 100;
    int warmup = 10;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--n") == 0 && i + 1 < argc) n = strtoull(argv[++i], 0, 10);
        else if (strcmp(argv[i], "--runs") == 0 && i + 1 < argc) runs = atoi(argv[++i]);
        else if (strcmp(argv[i], "--warmup") == 0 && i + 1 < argc) warmup = atoi(argv[++i]);
    }
    cudaDeviceProp prop;
    CK(cudaGetDeviceProperties(&prop, 0));
    printf("Poseidon2 S-box micro-bench\n");
    printf("  device: %s, sm_%d%d, %d SMs\n", prop.name, prop.major, prop.minor, prop.multiProcessorCount);
    printf("  N = %llu, runs = %d, warmup = %d\n", (unsigned long long)n, runs, warmup);
    printf("\n");
    printf("%-22s %12s %10s %14s\n", "Kernel", "median(ms)", "min(ms)", "Mops/sec");
    printf("------------------------------------------------------------------\n");

    BenchResult bb = run_one("BabyBear x^7  (4 mul)",  baby_bear_sbox_kernel,  n, 2013265921u, runs, warmup);
    BenchResult kb = run_one("KoalaBear x^3 (2 mul)", koala_bear_sbox_kernel, n, 2130706433u, runs, warmup);

    printf("%-22s %12.4f %10.4f %14.1f\n", bb.name, bb.median_ms, bb.min_ms, bb.mops_per_sec);
    printf("%-22s %12.4f %10.4f %14.1f\n", kb.name, kb.median_ms, kb.min_ms, kb.mops_per_sec);

    printf("\nKB / BB ratio: %.3fx (compute-bound expectation: ~2.0x; HBM-bound: ~1.0x)\n",
           kb.mops_per_sec / bb.mops_per_sec);
    return 0;
}
