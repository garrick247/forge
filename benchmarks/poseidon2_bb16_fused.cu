// poseidon2_bb16_fused.cu -- Fused BabyBear-16 Poseidon2 permutation kernel.
//
// Each thread runs one full perm (1 init M_E + 4 ext + 13 partial + 4 ext).
// State held in 16 register variables across all 22 layers; HBM touched
// only on initial load and final store.
//
// RCs and diagonal V values are byte-identical to Plonky3's
// BABYBEAR_POSEIDON2_RC_16_* and BabyBearInternalLayerParameters
// (baby-bear/src/poseidon2.rs), so the kernel computes byte-identical
// permutations to Plonky3's default_babybear_poseidon2_16.
//
// FORGE-emitted primitives (baby_bear_*, p2_ext_*) are inlined
// here in CUDA C — the SMT proof complexity for the full 1400-mul
// kernel exceeded what FORGE-Z3 could discharge in reasonable time.
// The chunk-step bench (demos/2006/2007) covers the verified case.

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <vector>
#include <random>
#include <algorithm>
#include <cuda_runtime.h>

#define BB_P 2013265921u

__constant__ uint32_t RC_EXT_INIT[64] = {
    1774958255u, 1185780729u, 1621102414u, 1796380621u, 588815102u, 1932426223u, 1925334750u, 747903232u,
    89648862u, 360728943u, 977184635u, 1425273457u, 256487465u, 1200041953u, 572403254u, 448208942u,
    1215789478u, 944884184u, 953948096u, 547326025u, 646827752u, 889997530u, 1536873262u, 86189867u,
    1065944411u, 32019634u, 333311454u, 456061748u, 1963448500u, 1827584334u, 1391160226u, 1348741381u,
    88424255u, 104111868u, 1763866748u, 79691676u, 1988915530u, 1050669594u, 359890076u, 573163527u,
    222820492u, 159256268u, 669703072u, 763177444u, 889367200u, 256335831u, 704371273u, 25886717u,
    51754520u, 1833211857u, 454499742u, 1384520381u, 777848065u, 1053320300u, 1851729162u, 344647910u,
    401996362u, 1046925956u, 5351995u, 1212119315u, 754867989u, 36972490u, 751272725u, 506915399u,
};
__constant__ uint32_t RC_EXT_FINAL[64] = {
    1922082829u, 1870549801u, 1502529704u, 1990744480u, 1700391016u, 1702593455u, 321330495u, 528965731u,
    183414327u, 1886297254u, 1178602734u, 1923111974u, 744004766u, 549271463u, 1781349648u, 542259047u,
    1536158148u, 715456982u, 503426110u, 340311124u, 1558555932u, 1226350925u, 742828095u, 1338992758u,
    1641600456u, 1843351545u, 301835475u, 43203215u, 386838401u, 1520185679u, 1235297680u, 904680097u,
    1491801617u, 1581784677u, 913384905u, 247083962u, 532844013u, 107190701u, 213827818u, 1979521776u,
    1358282574u, 1681743681u, 1867507480u, 1530706910u, 507181886u, 695185447u, 1172395131u, 1250800299u,
    1503161625u, 817684387u, 498481458u, 494676004u, 1404253825u, 108246855u, 59414691u, 744214112u,
    890862029u, 1342765939u, 1417398904u, 1897591937u, 1066647396u, 1682806907u, 1015795079u, 1619482808u,
};
__constant__ uint32_t RC_INT[13] = {
    1518359488u, 1765533241u, 945325693u, 422793067u, 311365592u, 1311448267u, 1629555936u, 1009879353u,
    190525218u, 786108885u, 557776863u, 212616710u, 605745517u,
};

// BB-16 internal-round diagonal V (canonical felts).
// V = [-2, 1, 2, 1/2, 3, 4, -1/2, -3, -4, 1/2^8, 1/4, 1/8, 1/2^27, -1/2^8, -1/16, -1/2^27]
__constant__ uint32_t V_DIAG[16] = {
    2013265919u, 1u, 2u, 1006632961u, 3u, 4u, 1006632960u, 2013265918u, 2013265917u,
    2005401601u, 1509949441u, 1761607681u, 2013265906u, 7864320u, 125829120u, 15u,
};

__device__ __forceinline__ uint32_t bb_add(uint32_t a, uint32_t b) {
    uint32_t s = a + b;
    return s >= BB_P ? s - BB_P : s;
}

__device__ __forceinline__ uint32_t bb_sub(uint32_t a, uint32_t b) {
    return a >= b ? a - b : a + BB_P - b;
}

__device__ __forceinline__ uint32_t bb_mul(uint32_t a, uint32_t b) {
    uint64_t prod = (uint64_t)a * (uint64_t)b;
    return (uint32_t)(prod % BB_P);
}

__device__ __forceinline__ uint32_t bb_double(uint32_t a) { return bb_add(a, a); }

__device__ __forceinline__ uint32_t bb_neg(uint32_t a) { return a == 0 ? 0 : BB_P - a; }

__device__ __forceinline__ uint32_t bb_sbox(uint32_t x) {
    uint32_t x2 = bb_mul(x, x);
    uint32_t x4 = bb_mul(x2, x2);
    uint32_t x6 = bb_mul(x4, x2);
    return bb_mul(x6, x);
}

// Apply M_E (block-circulant 4x4 MDS over chunks + chunk-sum mixing) to s[0..15].
__device__ __forceinline__ void apply_M_E(uint32_t s[16]) {
    // Per-chunk M_4: y0 = 2*x0 + 3*x1 + x2 + x3
    //                y1 = x0 + 2*x1 + 3*x2 + x3
    //                y2 = x0 + x1 + 2*x2 + 3*x3
    //                y3 = 3*x0 + x1 + x2 + 2*x3
    uint32_t y[16];
    #pragma unroll
    for (int k = 0; k < 4; k++) {
        uint32_t x0 = s[k*4 + 0];
        uint32_t x1 = s[k*4 + 1];
        uint32_t x2 = s[k*4 + 2];
        uint32_t x3 = s[k*4 + 3];
        uint32_t two_x0 = bb_double(x0);
        uint32_t two_x1 = bb_double(x1);
        uint32_t two_x2 = bb_double(x2);
        uint32_t two_x3 = bb_double(x3);
        uint32_t three_x0 = bb_add(two_x0, x0);
        uint32_t three_x1 = bb_add(two_x1, x1);
        uint32_t three_x2 = bb_add(two_x2, x2);
        uint32_t three_x3 = bb_add(two_x3, x3);
        // y0 = 2*x0 + 3*x1 + x2 + x3
        y[k*4 + 0] = bb_add(bb_add(bb_add(two_x0, three_x1), x2), x3);
        // y1 = x0 + 2*x1 + 3*x2 + x3
        y[k*4 + 1] = bb_add(bb_add(bb_add(x0, two_x1), three_x2), x3);
        // y2 = x0 + x1 + 2*x2 + 3*x3
        y[k*4 + 2] = bb_add(bb_add(bb_add(x0, x1), two_x2), three_x3);
        // y3 = 3*x0 + x1 + x2 + 2*x3
        y[k*4 + 3] = bb_add(bb_add(bb_add(three_x0, x1), x2), two_x3);
    }
    // Column sums across chunks: cs[j] = sum_k y[k*4 + j]
    uint32_t cs[4];
    #pragma unroll
    for (int j = 0; j < 4; j++) {
        uint32_t a = bb_add(y[0*4 + j], y[1*4 + j]);
        uint32_t b = bb_add(y[2*4 + j], y[3*4 + j]);
        cs[j] = bb_add(a, b);
    }
    // Final: s[k*4 + j] = y[k*4 + j] + cs[j]
    #pragma unroll
    for (int k = 0; k < 4; k++) {
        #pragma unroll
        for (int j = 0; j < 4; j++) {
            s[k*4 + j] = bb_add(y[k*4 + j], cs[j]);
        }
    }
}

// One external round: ARK + SBOX + M_E.
__device__ __forceinline__ void ext_round(uint32_t s[16], const uint32_t rc[16]) {
    #pragma unroll
    for (int i = 0; i < 16; i++) {
        s[i] = bb_sbox(bb_add(s[i], rc[i]));
    }
    apply_M_E(s);
}

// One internal/partial round: ARK[0] + SBOX[0] + M_I (= I + Diag(V)).
__device__ __forceinline__ void partial_round(uint32_t s[16], uint32_t rc) {
    s[0] = bb_sbox(bb_add(s[0], rc));
    // sum = sum_{i=0..15} s[i]
    uint32_t sum = s[0];
    #pragma unroll
    for (int i = 1; i < 16; i++) {
        sum = bb_add(sum, s[i]);
    }
    // new_state[i] = V[i] * s[i] + sum
    // V[0] = -2, so new[0] = -2*s[0] + sum = sum - 2*s[0]
    s[0] = bb_sub(sum, bb_double(s[0]));
    // V[1] = 1: new[1] = s[1] + sum
    s[1] = bb_add(s[1], sum);
    #pragma unroll
    for (int i = 2; i < 16; i++) {
        s[i] = bb_add(bb_mul(s[i], V_DIAG[i]), sum);
    }
}

extern "C" __global__ void poseidon2_bb16_fused_kernel(
    uint32_t* __restrict__ out,
    const uint32_t* __restrict__ state_in,
    uint64_t n)
{
    uint64_t tid = (uint64_t)blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= n) return;

    uint32_t s[16];
    #pragma unroll
    for (int i = 0; i < 16; i++) {
        s[i] = state_in[16 * tid + i];
    }

    // Initial linear layer (M_E only, no ARK, no SBOX).
    apply_M_E(s);

    // 4 initial external rounds.
    #pragma unroll
    for (int r = 0; r < 4; r++) {
        ext_round(s, &RC_EXT_INIT[r * 16]);
    }

    // 13 partial rounds.
    #pragma unroll
    for (int r = 0; r < 13; r++) {
        partial_round(s, RC_INT[r]);
    }

    // 4 terminal external rounds.
    #pragma unroll
    for (int r = 0; r < 4; r++) {
        ext_round(s, &RC_EXT_FINAL[r * 16]);
    }

    #pragma unroll
    for (int i = 0; i < 16; i++) {
        out[16 * tid + i] = s[i];
    }
}
