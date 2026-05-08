// bench_runner.cu -- micro-benchmark FORGE-emitted field kernels.
// Compiled and linked alongside three separate FORGE .cu translation units.
// Forward-declares the kernels by signature (FORGE's emitted form).

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <vector>
#include <random>
#include <algorithm>
#include <cuda_runtime.h>

extern __global__ void baby_bear_mul_kernel(
    uint32_t* __restrict__ out, uint64_t out_len,
    uint32_t* __restrict__ a, uint64_t a_len,
    uint32_t* __restrict__ b, uint64_t b_len,
    uint64_t n);
extern __global__ void koala_bear_mul_kernel(
    uint32_t* __restrict__ out, uint64_t out_len,
    uint32_t* __restrict__ a, uint64_t a_len,
    uint32_t* __restrict__ b, uint64_t b_len,
    uint64_t n);
extern __global__ void m31_mul_kernel(
    uint32_t* __restrict__ out, uint64_t out_len,
    uint32_t* __restrict__ a, uint64_t a_len,
    uint32_t* __restrict__ b, uint64_t b_len,
    uint64_t n);

#define CK(call) do {                                                        \
    cudaError_t e = (call);                                                  \
    if (e != cudaSuccess) {                                                  \
        fprintf(stderr, "CUDA error %s:%d: %s\n",                            \
                __FILE__, __LINE__, cudaGetErrorString(e));                  \
        exit(1);                                                             \
    }                                                                        \
} while (0)

struct BenchResult {
    const char* name;
    double median_ms;
    double min_ms;
    double mops_per_sec;
    uint32_t first_out;
    uint32_t last_out;
};

typedef void (*KernelPtr)(uint32_t*, uint64_t, uint32_t*, uint64_t,
                          uint32_t*, uint64_t, uint64_t);

static BenchResult run_one(const char* name, KernelPtr kernel,
                           uint64_t n, uint32_t prime, int runs, int warmup) {
    std::vector<uint32_t> a_h(n), b_h(n), out_h(n);
    std::mt19937 rng(42);
    for (uint64_t i = 0; i < n; i++) {
        a_h[i] = (uint32_t)(rng() % prime);
        b_h[i] = (uint32_t)(rng() % prime);
    }
    uint32_t *a_d, *b_d, *out_d;
    CK(cudaMalloc(&a_d, n * sizeof(uint32_t)));
    CK(cudaMalloc(&b_d, n * sizeof(uint32_t)));
    CK(cudaMalloc(&out_d, n * sizeof(uint32_t)));
    CK(cudaMemcpy(a_d, a_h.data(), n * sizeof(uint32_t), cudaMemcpyHostToDevice));
    CK(cudaMemcpy(b_d, b_h.data(), n * sizeof(uint32_t), cudaMemcpyHostToDevice));

    int threads = 256;
    int blocks = (int)((n + threads - 1) / threads);

    for (int i = 0; i < warmup; i++) {
        kernel<<<blocks, threads>>>(out_d, n, a_d, n, b_d, n, n);
    }
    CK(cudaDeviceSynchronize());

    std::vector<float> times;
    cudaEvent_t evStart, evStop;
    CK(cudaEventCreate(&evStart));
    CK(cudaEventCreate(&evStop));
    for (int i = 0; i < runs; i++) {
        CK(cudaEventRecord(evStart));
        kernel<<<blocks, threads>>>(out_d, n, a_d, n, b_d, n, n);
        CK(cudaEventRecord(evStop));
        CK(cudaEventSynchronize(evStop));
        float ms;
        CK(cudaEventElapsedTime(&ms, evStart, evStop));
        times.push_back(ms);
    }
    CK(cudaEventDestroy(evStart));
    CK(cudaEventDestroy(evStop));

    CK(cudaMemcpy(out_h.data(), out_d, n * sizeof(uint32_t), cudaMemcpyDeviceToHost));

    std::sort(times.begin(), times.end());
    double median = times[runs / 2];
    double min_ms = times[0];
    double mops = (double)n / (median / 1000.0) / 1e6;

    BenchResult r{ name, median, min_ms, mops, out_h[0], out_h[n - 1] };

    CK(cudaFree(a_d));
    CK(cudaFree(b_d));
    CK(cudaFree(out_d));
    return r;
}

int main(int argc, char** argv) {
    uint64_t n = 16777216;       // 16M
    int runs = 100;
    int warmup = 10;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--n") == 0 && i + 1 < argc) n = strtoull(argv[++i], 0, 10);
        else if (strcmp(argv[i], "--runs") == 0 && i + 1 < argc) runs = atoi(argv[++i]);
        else if (strcmp(argv[i], "--warmup") == 0 && i + 1 < argc) warmup = atoi(argv[++i]);
    }
    cudaDeviceProp prop;
    CK(cudaGetDeviceProperties(&prop, 0));
    printf("FORGE-emitted field-mul micro-bench\n");
    printf("  device: %s, sm_%d%d, %d SMs\n", prop.name, prop.major, prop.minor, prop.multiProcessorCount);
    printf("  N = %llu, runs = %d, warmup = %d\n", (unsigned long long)n, runs, warmup);
    printf("\n");
    printf("%-22s %12s %10s %14s\n", "Kernel", "median(ms)", "min(ms)", "Mops/sec");
    printf("------------------------------------------------------------------\n");

    std::vector<BenchResult> results;
    results.push_back(run_one("BabyBear mul",       baby_bear_mul_kernel,  n, 2013265921u, runs, warmup));
    results.push_back(run_one("KoalaBear mul",      koala_bear_mul_kernel, n, 2130706433u, runs, warmup));
    results.push_back(run_one("M31 mul (baseline)", m31_mul_kernel,        n, 2147483647u, runs, warmup));

    for (auto& r : results) {
        printf("%-22s %12.4f %10.4f %14.1f\n",
               r.name, r.median_ms, r.min_ms, r.mops_per_sec);
    }

    printf("\nRelative throughput (M31 = 1.00x baseline):\n");
    double m31 = results[2].mops_per_sec;
    for (auto& r : results) {
        printf("  %-22s %.3fx\n", r.name, r.mops_per_sec / m31);
    }
    return 0;
}
