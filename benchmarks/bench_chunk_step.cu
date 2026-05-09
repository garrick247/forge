// bench_chunk_step.cu -- Poseidon2 chunk-step throughput on RTX 5090.
// One chunk-step = 4 ARK + 4 SBOX + 4x4 MDS = one chunk's worth of one
// Poseidon2 external round. Width-16 BB perm has 4 chunks * 8 ext rounds
// = 32 chunk-steps per perm (rough; partial rounds not counted here).

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <vector>
#include <random>
#include <algorithm>
#include <cuda_runtime.h>

extern __global__ void baby_bear_chunk_step_kernel(
    uint32_t* __restrict__ out, uint64_t out_len,
    uint32_t* __restrict__ state, uint64_t state_len,
    uint32_t* __restrict__ rc, uint64_t rc_len,
    uint64_t n);
extern __global__ void koala_bear_chunk_step_kernel(
    uint32_t* __restrict__ out, uint64_t out_len,
    uint32_t* __restrict__ state, uint64_t state_len,
    uint32_t* __restrict__ rc, uint64_t rc_len,
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
    double mchunks_per_sec;       // millions of chunk-steps per second
    double mperms_equiv_per_sec;  // perms equivalent (32 chunk-steps/perm rough)
};

typedef void (*KernelPtr)(uint32_t*, uint64_t, uint32_t*, uint64_t,
                          uint32_t*, uint64_t, uint64_t);

static BenchResult run_one(const char* name, KernelPtr kernel,
                           uint64_t n_chunks, uint32_t prime,
                           int runs, int warmup) {
    uint64_t felts = 4 * n_chunks;
    std::vector<uint32_t> state_h(felts), rc_h(felts);
    std::mt19937 rng(42);
    for (uint64_t i = 0; i < felts; i++) {
        state_h[i] = (uint32_t)(rng() % prime);
        rc_h[i] = (uint32_t)(rng() % prime);
    }
    uint32_t *state_d, *rc_d, *out_d;
    CK(cudaMalloc(&state_d, felts * sizeof(uint32_t)));
    CK(cudaMalloc(&rc_d, felts * sizeof(uint32_t)));
    CK(cudaMalloc(&out_d, felts * sizeof(uint32_t)));
    CK(cudaMemcpy(state_d, state_h.data(), felts * sizeof(uint32_t), cudaMemcpyHostToDevice));
    CK(cudaMemcpy(rc_d, rc_h.data(), felts * sizeof(uint32_t), cudaMemcpyHostToDevice));

    int threads = 256;
    int blocks = (int)((n_chunks + threads - 1) / threads);

    for (int i = 0; i < warmup; i++) {
        kernel<<<blocks, threads>>>(out_d, felts, state_d, felts, rc_d, felts, n_chunks);
    }
    CK(cudaDeviceSynchronize());

    std::vector<float> times;
    cudaEvent_t evStart, evStop;
    CK(cudaEventCreate(&evStart));
    CK(cudaEventCreate(&evStop));
    for (int i = 0; i < runs; i++) {
        CK(cudaEventRecord(evStart));
        kernel<<<blocks, threads>>>(out_d, felts, state_d, felts, rc_d, felts, n_chunks);
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
    double mchunks = (double)n_chunks / (median / 1000.0) / 1e6;
    double mperms = mchunks / 32.0;  // 4 chunks * 8 external rounds (ext-only approx)

    BenchResult r{ name, median, min_ms, mchunks, mperms };

    CK(cudaFree(state_d));
    CK(cudaFree(rc_d));
    CK(cudaFree(out_d));
    return r;
}

int main(int argc, char** argv) {
    uint64_t n = 4194304;          // 4M chunks = 16M felts
    int runs = 100;
    int warmup = 10;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--n") == 0 && i + 1 < argc) n = strtoull(argv[++i], 0, 10);
        else if (strcmp(argv[i], "--runs") == 0 && i + 1 < argc) runs = atoi(argv[++i]);
        else if (strcmp(argv[i], "--warmup") == 0 && i + 1 < argc) warmup = atoi(argv[++i]);
    }
    cudaDeviceProp prop;
    CK(cudaGetDeviceProperties(&prop, 0));
    printf("Poseidon2 chunk-step micro-bench\n");
    printf("  device: %s, sm_%d%d, %d SMs\n", prop.name, prop.major, prop.minor, prop.multiProcessorCount);
    printf("  N chunks = %llu (= %llu felts of state + %llu felts of rc + %llu felts out)\n",
           (unsigned long long)n, (unsigned long long)(4*n),
           (unsigned long long)(4*n), (unsigned long long)(4*n));
    printf("  runs = %d, warmup = %d\n", runs, warmup);
    printf("\n");
    printf("%-30s %12s %10s %14s %18s\n", "Kernel", "median(ms)", "min(ms)", "M-chunks/s", "M-perms-equiv/s");
    printf("------------------------------------------------------------------------------------------\n");

    BenchResult bb = run_one("BabyBear  chunk-step (x^7+MDS)", baby_bear_chunk_step_kernel,  n, 2013265921u, runs, warmup);
    BenchResult kb = run_one("KoalaBear chunk-step (x^3+MDS)", koala_bear_chunk_step_kernel, n, 2130706433u, runs, warmup);

    printf("%-30s %12.4f %10.4f %14.1f %18.2f\n", bb.name, bb.median_ms, bb.min_ms, bb.mchunks_per_sec, bb.mperms_equiv_per_sec);
    printf("%-30s %12.4f %10.4f %14.1f %18.2f\n", kb.name, kb.median_ms, kb.min_ms, kb.mchunks_per_sec, kb.mperms_equiv_per_sec);

    printf("\nKB / BB ratio: %.3fx\n", kb.mchunks_per_sec / bb.mchunks_per_sec);
    printf("Note: M-perms-equiv counts only external-round chunks (4 chunks * 8 rounds = 32/perm).\n");
    printf("      Real BB-16 Poseidon2 also has 13 partial rounds (~13 sbox + 16-elem mixing each).\n");
    return 0;
}
