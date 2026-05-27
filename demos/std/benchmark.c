/* Forge felt252 runtime benchmark.
 *
 * Microbenchmarks the verified C99 output of demos/std/felt252.fg for the
 * key Stark crypto primitives. Compares against the verification baseline
 * (Forge's own discharge time, ~2,100s for the full file).
 *
 * Build:
 *   gcc -O2 -o bench felt252.c benchmark.c
 *
 * Run:
 *   ./bench
 */
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

/* Forward declarations of the C tuple types Forge emits. */
typedef struct { uint32_t _0; uint32_t _1; uint32_t _2; uint32_t _3;
                 uint32_t _4; uint32_t _5; uint32_t _6; uint32_t _7;
} __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t;

typedef struct { uint32_t _0; uint32_t _1; uint32_t _2; uint32_t _3;
                 uint32_t _4; uint32_t _5; uint32_t _6; uint32_t _7;
                 uint32_t _8; uint32_t _9; uint32_t _10; uint32_t _11;
                 uint32_t _12; uint32_t _13; uint32_t _14; uint32_t _15;
} __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t;

typedef struct { uint32_t _0; uint32_t _1; uint32_t _2; uint32_t _3;
                 uint32_t _4; uint32_t _5; uint32_t _6; uint32_t _7;
                 uint32_t _8; uint32_t _9; uint32_t _10; uint32_t _11;
                 uint32_t _12; uint32_t _13; uint32_t _14; uint32_t _15;
                 uint32_t _16; uint32_t _17; uint32_t _18; uint32_t _19;
                 uint32_t _20; uint32_t _21; uint32_t _22; uint32_t _23;
} __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t;

/* Function signatures (matching felt252.c). */
__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t felt252_mul(
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t felt252_sqr(
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t felt252_inv(
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t pedersen_full(
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t
hades_permutation_full(
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

uint32_t ecdsa_verify(
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t,
    uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t);

/* High-resolution timing. */
static inline uint64_t now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

/* Volatile sinks to prevent dead-code elimination. */
static volatile uint32_t sink_u32 = 0;

static void sink_8(__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t r) {
    sink_u32 ^= r._0 ^ r._1 ^ r._2 ^ r._3 ^ r._4 ^ r._5 ^ r._6 ^ r._7;
}

static void sink_16(__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t r) {
    sink_u32 ^= r._0 ^ r._1 ^ r._2 ^ r._3 ^ r._4 ^ r._5 ^ r._6 ^ r._7
              ^ r._8 ^ r._9 ^ r._10 ^ r._11 ^ r._12 ^ r._13 ^ r._14 ^ r._15;
}

static void sink_24(__forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t r) {
    sink_u32 ^= r._0 ^ r._8 ^ r._16;
}

/* Test inputs — semi-random valid felt252 values (low 252 bits set, but
 * limb 7's top 24 bits zero so they're canonical < P). */
static const uint32_t TEST_A[8] = {
    0xDEADBEEF, 0xCAFEBABE, 0x12345678, 0x87654321,
    0xABCDEF01, 0x10FEDCBA, 0x55555555, 0x07654321 /* top byte 0x07 < 0x08 */
};
static const uint32_t TEST_B[8] = {
    0x11111111, 0x22222222, 0x33333333, 0x44444444,
    0x55555555, 0x66666666, 0x77777777, 0x07888888
};

static void bench_felt252_mul(int iters) {
    uint64_t t0 = now_ns();
    for (int i = 0; i < iters; i++) {
        __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t r = felt252_mul(
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3],
            TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7],
            TEST_B[0], TEST_B[1], TEST_B[2], TEST_B[3],
            TEST_B[4], TEST_B[5], TEST_B[6], TEST_B[7]);
        sink_8(r);
    }
    uint64_t dt = now_ns() - t0;
    double ns_per = (double)dt / iters;
    double ops_per_sec = 1e9 / ns_per;
    printf("  felt252_mul         %d iters  %10.1f ns/op  %12.0f ops/sec\n",
           iters, ns_per, ops_per_sec);
}

static void bench_felt252_sqr(int iters) {
    uint64_t t0 = now_ns();
    for (int i = 0; i < iters; i++) {
        __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t r = felt252_sqr(
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3],
            TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7]);
        sink_8(r);
    }
    uint64_t dt = now_ns() - t0;
    double ns_per = (double)dt / iters;
    double ops_per_sec = 1e9 / ns_per;
    printf("  felt252_sqr         %d iters  %10.1f ns/op  %12.0f ops/sec\n",
           iters, ns_per, ops_per_sec);
}

static void bench_felt252_inv(int iters) {
    uint64_t t0 = now_ns();
    for (int i = 0; i < iters; i++) {
        __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_t r = felt252_inv(
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3],
            TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7]);
        sink_8(r);
    }
    uint64_t dt = now_ns() - t0;
    double ns_per = (double)dt / iters;
    double ops_per_sec = 1e9 / ns_per;
    printf("  felt252_inv         %d iters  %10.1f ns/op  %12.0f ops/sec\n",
           iters, ns_per, ops_per_sec);
}

static void bench_pedersen_full(int iters) {
    uint64_t t0 = now_ns();
    for (int i = 0; i < iters; i++) {
        __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t r = pedersen_full(
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3],
            TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7],
            TEST_B[0], TEST_B[1], TEST_B[2], TEST_B[3],
            TEST_B[4], TEST_B[5], TEST_B[6], TEST_B[7]);
        sink_16(r);
    }
    uint64_t dt = now_ns() - t0;
    double ns_per = (double)dt / iters;
    double ops_per_sec = 1e9 / ns_per;
    double us_per = ns_per / 1000.0;
    printf("  pedersen_full       %d iters  %10.2f us/op  %12.0f ops/sec\n",
           iters, us_per, ops_per_sec);
}

static void bench_hades(int iters) {
    uint64_t t0 = now_ns();
    for (int i = 0; i < iters; i++) {
        __forge_tuple_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_u32_t r = hades_permutation_full(
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3],
            TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7],
            TEST_B[0], TEST_B[1], TEST_B[2], TEST_B[3],
            TEST_B[4], TEST_B[5], TEST_B[6], TEST_B[7],
            1, 0, 0, 0, 0, 0, 0, 0);
        sink_24(r);
    }
    uint64_t dt = now_ns() - t0;
    double ns_per = (double)dt / iters;
    double ops_per_sec = 1e9 / ns_per;
    double us_per = ns_per / 1000.0;
    printf("  hades_permutation   %d iters  %10.2f us/op  %12.0f ops/sec\n",
           iters, us_per, ops_per_sec);
}

static void bench_ecdsa_verify(int iters) {
    uint64_t t0 = now_ns();
    for (int i = 0; i < iters; i++) {
        uint32_t r = ecdsa_verify(
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3], TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7],
            TEST_B[0], TEST_B[1], TEST_B[2], TEST_B[3], TEST_B[4], TEST_B[5], TEST_B[6], TEST_B[7],
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3], TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7],
            TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3], TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7],
            TEST_B[0], TEST_B[1], TEST_B[2], TEST_B[3], TEST_B[4], TEST_B[5], TEST_B[6], TEST_B[7]);
        sink_u32 ^= r;
    }
    uint64_t dt = now_ns() - t0;
    double ns_per = (double)dt / iters;
    double ops_per_sec = 1e9 / ns_per;
    double ms_per = ns_per / 1e6;
    printf("  ecdsa_verify        %d iters  %10.2f ms/op  %12.1f ops/sec\n",
           iters, ms_per, ops_per_sec);
}

int main(void) {
    printf("Forge felt252.fg runtime benchmarks (single-thread, x86-64)\n");
    printf("============================================================\n\n");

    /* Warmup. */
    for (int i = 0; i < 100; i++) {
        sink_8(felt252_mul(TEST_A[0], TEST_A[1], TEST_A[2], TEST_A[3],
                            TEST_A[4], TEST_A[5], TEST_A[6], TEST_A[7],
                            TEST_B[0], TEST_B[1], TEST_B[2], TEST_B[3],
                            TEST_B[4], TEST_B[5], TEST_B[6], TEST_B[7]));
    }

    printf("Field operations (mod P):\n");
    bench_felt252_mul(2000000);
    bench_felt252_sqr(2000000);
    bench_felt252_inv(20000);
    printf("\n");

    printf("Hash functions:\n");
    bench_hades(50000);
    bench_pedersen_full(100);
    printf("\n");

    printf("ECDSA signature verification:\n");
    bench_ecdsa_verify(50);
    printf("\n");

    printf("Sink (anti-DCE): 0x%08x\n", sink_u32);
    return 0;
}
