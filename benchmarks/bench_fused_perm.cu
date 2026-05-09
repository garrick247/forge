// bench_fused_perm.cu -- Fused BB-16 Poseidon2 permutation bench.
//
// Verifies byte-identity vs Plonky3's default_babybear_poseidon2_16
// using their published test vector, then measures throughput at scale.

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <vector>
#include <random>
#include <algorithm>
#include <cuda_runtime.h>

extern "C" __global__ void poseidon2_bb16_fused_kernel(
    uint32_t* __restrict__ out,
    const uint32_t* __restrict__ state_in,
    uint64_t n);

#define CK(call) do {                                                        \
    cudaError_t err = (call);                                                \
    if (err != cudaSuccess) {                                                \
        fprintf(stderr, "CUDA error %s:%d: %s\n",                            \
                __FILE__, __LINE__, cudaGetErrorString(err));                \
        exit(1);                                                             \
    }                                                                        \
} while (0)

// Plonky3 BB-16 test vector (from baby-bear/src/poseidon2.rs, test_default_babybear_poseidon2_width_16).
static const uint32_t PLONKY3_BB16_INPUT[16] = {
    894848333, 1437655012, 1200606629, 1690012884, 71131202, 1749206695, 1717947831,
    120589055, 19776022, 42382981, 1831865506, 724844064, 171220207, 1299207443, 227047920,
    1783754913
};
static const uint32_t PLONKY3_BB16_EXPECTED[16] = {
    516096821, 90309867, 1101817252, 1660784290, 360715097, 1789519026, 1788910906,
    563338433, 319524748, 1741414159, 1650859320, 894311162, 1121347488, 1692793758,
    1052633829, 1344246938
};

static int verify_correctness() {
    // Run the kernel on N=1 with the Plonky3 test input; check byte-identity.
    uint32_t *state_d, *out_d;
    uint32_t out_h[16] = {0};
    CK(cudaMalloc(&state_d, 16 * sizeof(uint32_t)));
    CK(cudaMalloc(&out_d, 16 * sizeof(uint32_t)));
    CK(cudaMemcpy(state_d, PLONKY3_BB16_INPUT, 16 * sizeof(uint32_t), cudaMemcpyHostToDevice));

    poseidon2_bb16_fused_kernel<<<1, 32>>>(out_d, state_d, 1);
    CK(cudaDeviceSynchronize());

    CK(cudaMemcpy(out_h, out_d, 16 * sizeof(uint32_t), cudaMemcpyDeviceToHost));
    CK(cudaFree(state_d));
    CK(cudaFree(out_d));

    int mismatches = 0;
    printf("Correctness check (Plonky3 BB-16 test vector):\n");
    printf("  i  | expected     | got          | match\n");
    printf("  ---+--------------+--------------+------\n");
    for (int i = 0; i < 16; i++) {
        int ok = (out_h[i] == PLONKY3_BB16_EXPECTED[i]);
        printf("  %2d | %12u | %12u | %s\n", i,
               PLONKY3_BB16_EXPECTED[i], out_h[i], ok ? "OK" : "MISMATCH");
        if (!ok) mismatches++;
    }
    if (mismatches == 0) {
        printf("\n  PASS: byte-identical to Plonky3 default_babybear_poseidon2_16.\n\n");
        return 0;
    } else {
        printf("\n  FAIL: %d mismatches.\n\n", mismatches);
        return 1;
    }
}

static void bench(uint64_t n, int runs, int warmup) {
    uint32_t prime = 2013265921u;
    std::vector<uint32_t> state_h(16 * n), out_h(16 * n);
    std::mt19937 rng(42);
    for (uint64_t i = 0; i < 16 * n; i++) {
        state_h[i] = (uint32_t)(rng() % prime);
    }
    uint32_t *state_d, *out_d;
    CK(cudaMalloc(&state_d, 16 * n * sizeof(uint32_t)));
    CK(cudaMalloc(&out_d, 16 * n * sizeof(uint32_t)));
    CK(cudaMemcpy(state_d, state_h.data(), 16 * n * sizeof(uint32_t), cudaMemcpyHostToDevice));

    int threads = 256;
    int blocks = (int)((n + threads - 1) / threads);

    for (int i = 0; i < warmup; i++) {
        poseidon2_bb16_fused_kernel<<<blocks, threads>>>(out_d, state_d, n);
    }
    CK(cudaDeviceSynchronize());

    std::vector<float> times;
    cudaEvent_t evStart, evStop;
    CK(cudaEventCreate(&evStart));
    CK(cudaEventCreate(&evStop));
    for (int i = 0; i < runs; i++) {
        CK(cudaEventRecord(evStart));
        poseidon2_bb16_fused_kernel<<<blocks, threads>>>(out_d, state_d, n);
        CK(cudaEventRecord(evStop));
        CK(cudaEventSynchronize(evStop));
        float ms;
        CK(cudaEventElapsedTime(&ms, evStart, evStop));
        times.push_back(ms);
    }
    CK(cudaEventDestroy(evStart));
    CK(cudaEventDestroy(evStop));

    std::sort(times.begin(), times.end());
    double median_ms = times[runs / 2];
    double min_ms = times[0];
    double mperms_per_sec = (double)n / (median_ms / 1000.0) / 1e6;

    printf("  N = %llu perms, median %.4f ms, min %.4f ms, %.2f M-perms/sec\n",
           (unsigned long long)n, median_ms, min_ms, mperms_per_sec);

    CK(cudaFree(state_d));
    CK(cudaFree(out_d));
}

int main(int argc, char** argv) {
    int runs = 100;
    int warmup = 10;
    int do_verify = 1;
    int do_bench = 1;
    uint64_t n_single = 0;
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--runs") == 0 && i + 1 < argc) runs = atoi(argv[++i]);
        else if (strcmp(argv[i], "--warmup") == 0 && i + 1 < argc) warmup = atoi(argv[++i]);
        else if (strcmp(argv[i], "--no-verify") == 0) do_verify = 0;
        else if (strcmp(argv[i], "--no-bench") == 0) do_bench = 0;
        else if (strcmp(argv[i], "--n") == 0 && i + 1 < argc) n_single = strtoull(argv[++i], 0, 10);
    }
    cudaDeviceProp prop;
    CK(cudaGetDeviceProperties(&prop, 0));
    printf("Fused BB-16 Poseidon2 perm bench\n");
    printf("  device: %s, sm_%d%d, %d SMs\n", prop.name, prop.major, prop.minor, prop.multiProcessorCount);
    printf("  runs = %d, warmup = %d\n", runs, warmup);
    printf("\n");

    int rc = 0;
    if (do_verify) rc = verify_correctness();
    if (rc != 0) return rc;

    if (do_bench) {
        printf("Throughput sweep:\n");
        if (n_single > 0) {
            bench(n_single, runs, warmup);
        } else {
            for (uint64_t n : {(uint64_t)1024, (uint64_t)8192, (uint64_t)65536, (uint64_t)262144,
                              (uint64_t)1048576, (uint64_t)4194304, (uint64_t)16777216}) {
                bench(n, runs, warmup);
            }
        }
    }
    return 0;
}
