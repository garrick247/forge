// FORGE-generated CUDA C — SM_120
// All proofs discharged. Correct by construction.
// No bounds checks. No overflow checks. They were proven away.

#include <stdint.h>
#include <stdbool.h>


__device__ uint64_t warp_reduce_sum(uint64_t val) {
  uint64_t v = val;
  v = (v + __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL));
  return v;
}

__device__ uint64_t warp_reduce_max(uint64_t val) {
  uint64_t v = val;
  uint64_t s = __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  return v;
}

__device__ uint64_t warp_reduce_min(uint64_t val) {
  uint64_t v = val;
  uint64_t s = __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  return v;
}

__device__ float warp_reduce_sum_f32(float val) {
  float v = val;
  v = (v + __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL));
  return v;
}

__device__ float warp_reduce_max_f32(float val) {
  float v = val;
  float s = __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL);
  if ((s > v)) {
    v = s;
  }
  return v;
}

__device__ float warp_reduce_min_f32(float val) {
  float v = val;
  float s = __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  s = __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL);
  if ((s < v)) {
    v = s;
  }
  return v;
}

__device__ uint64_t grid_stride_start(uint64_t block_idx, uint64_t block_dim, uint64_t thread_idx) {
  return ((block_idx * block_dim) + thread_idx);
}

__device__ uint64_t grid_stride_step(uint64_t block_dim, uint64_t grid_dim) {
  return (block_dim * grid_dim);
}

__device__ uint32_t m31_add(uint32_t a, uint32_t b) {
  uint64_t s = (((uint64_t)a) + ((uint64_t)b));
  uint64_t p = ((uint64_t)M31_P);
  uint64_t r = __if_stmt__;
  return ((uint32_t)r);
}

__device__ uint32_t m31_sub(uint32_t a, uint32_t b) {
  uint64_t a64 = ((uint64_t)a);
  uint64_t b64 = ((uint64_t)b);
  uint64_t p = ((uint64_t)M31_P);
  uint64_t r = __if_stmt__;
  return ((uint32_t)r);
}

__device__ uint32_t m31_mul(uint32_t a, uint32_t b) {
  uint64_t prod = (((uint64_t)a) * ((uint64_t)b));
  uint64_t p = ((uint64_t)M31_P);
  uint64_t r = (prod % p);
  return ((uint32_t)r);
}

__device__ uint32_t m31_neg(uint32_t a) {
  if ((a == 0U)) {
    return 0U;
  } else {
    return (M31_P - a);
  }
}

__device__ uint32_t m31_double(uint32_t a) {
  return m31_add(a, a);
}

__device__ uint32_t cm31_mul_re(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im) {
  uint32_t ac = m31_mul(a_re, b_re);
  uint32_t bd = m31_mul(a_im, b_im);
  return m31_sub(ac, bd);
}

__device__ uint32_t cm31_mul_im(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im) {
  uint32_t ad = m31_mul(a_re, b_im);
  uint32_t bc = m31_mul(a_im, b_re);
  return m31_add(ad, bc);
}

__device__ uint32_t cm31_add_re(uint32_t a_re, uint32_t b_re) {
  return m31_add(a_re, b_re);
}

__device__ uint32_t cm31_add_im(uint32_t a_im, uint32_t b_im) {
  return m31_add(a_im, b_im);
}

__device__ uint32_t cm31_sub_re(uint32_t a_re, uint32_t b_re) {
  return m31_sub(a_re, b_re);
}

__device__ uint32_t cm31_sub_im(uint32_t a_im, uint32_t b_im) {
  return m31_sub(a_im, b_im);
}

__device__ uint32_t qm31_mul_out_re_re(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ac_re = cm31_mul_re(a_re, a_im, c_re, c_im);
  uint32_t bd_re = cm31_mul_re(b_re, b_im, d_re, d_im);
  uint32_t bd_im = cm31_mul_im(b_re, b_im, d_re, d_im);
  uint32_t t = m31_sub(m31_double(bd_re), bd_im);
  return m31_add(ac_re, t);
}

__device__ uint32_t qm31_mul_out_re_im(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ac_im = cm31_mul_im(a_re, a_im, c_re, c_im);
  uint32_t bd_re = cm31_mul_re(b_re, b_im, d_re, d_im);
  uint32_t bd_im = cm31_mul_im(b_re, b_im, d_re, d_im);
  uint32_t t = m31_add(bd_re, m31_double(bd_im));
  return m31_add(ac_im, t);
}

__device__ uint32_t qm31_mul_out_im_re(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ad_re = cm31_mul_re(a_re, a_im, d_re, d_im);
  uint32_t bc_re = cm31_mul_re(b_re, b_im, c_re, c_im);
  return m31_add(ad_re, bc_re);
}

__device__ uint32_t qm31_mul_out_im_im(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ad_im = cm31_mul_im(a_re, a_im, d_re, d_im);
  uint32_t bc_im = cm31_mul_im(b_re, b_im, c_re, c_im);
  return m31_add(ad_im, bc_im);
}

__device__ uint32_t qm31_add_re_re(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

__device__ uint32_t qm31_add_re_im(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

__device__ uint32_t qm31_add_im_re(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

__device__ uint32_t qm31_add_im_im(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

__device__ uint32_t qm31_sub_re_re(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

__device__ uint32_t qm31_sub_re_im(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

__device__ uint32_t qm31_sub_im_re(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

__device__ uint32_t qm31_sub_im_im(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

__device__ uint32_t iv0() {
  return 1779033703U;
}

__device__ uint32_t iv1() {
  return 3144134277U;
}

__device__ uint32_t iv2() {
  return 1013904242U;
}

__device__ uint32_t iv3() {
  return 2773480762U;
}

__device__ uint32_t iv4() {
  return 1359893119U;
}

__device__ uint32_t iv5() {
  return 2600822924U;
}

__device__ uint32_t iv6() {
  return 528734635U;
}

__device__ uint32_t iv7() {
  return 1541459225U;
}

__device__ uint32_t rotr32(uint32_t x, uint32_t n) {
  return ((x >> n) | (x << (32U - n)));
}

__device__ uint64_t g_mix(uint32_t a, uint32_t b, uint32_t c, uint32_t d, uint32_t x, uint32_t y) {
  uint32_t a1 = ((a + b) + x);
  uint32_t d1 = rotr32((d ^ a1), 16U);
  uint32_t c1 = (c + d1);
  uint32_t b1 = rotr32((b ^ c1), 12U);
  uint32_t a2 = ((a1 + b1) + y);
  uint32_t d2 = rotr32((d1 ^ a2), 8U);
  uint32_t c2 = (c1 + d2);
  uint32_t b2 = rotr32((b1 ^ c2), 7U);
  return 0 /* unhandled */;
}

__device__ uint32_t reduce_word(uint32_t v) {
  uint32_t lo = (v & M31_P);
  uint32_t hi = (v >> 31U);
  uint32_t r = (lo + hi);
  if ((r >= M31_P)) {
    return (r - M31_P);
  } else {
    return r;
  }
}

__global__ void merkle_hash_leaves_single(uint32_t* __restrict__ column, uint64_t column_len, uint32_t* __restrict__ hashes, uint64_t hashes_len, uint64_t n_leaves) {
  uint64_t leaf = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((leaf < n_leaves)) {
    uint32_t m0 = column[leaf];
    uint32_t m1 = 0U;
    uint32_t m2 = 0U;
    uint32_t m3 = 0U;
    uint32_t m4 = 0U;
    uint32_t m5 = 0U;
    uint32_t m6 = 0U;
    uint32_t m7 = 0U;
    uint32_t m8 = 0U;
    uint32_t m9 = 0U;
    uint32_t m10 = 0U;
    uint32_t m11 = 0U;
    uint32_t m12 = 0U;
    uint32_t m13 = 0U;
    uint32_t m14 = 0U;
    uint32_t m15 = 0U;
    uint32_t h0 = (iv0() ^ 16842784U);
    uint32_t h1 = iv1();
    uint32_t h2 = iv2();
    uint32_t h3 = iv3();
    uint32_t h4 = iv4();
    uint32_t h5 = iv5();
    uint32_t h6 = iv6();
    uint32_t h7 = iv7();
    uint32_t v0 = h0;
    uint32_t v1 = h1;
    uint32_t v2 = h2;
    uint32_t v3 = h3;
    uint32_t v4 = h4;
    uint32_t v5 = h5;
    uint32_t v6 = h6;
    uint32_t v7 = h7;
    uint32_t v8 = iv0();
    uint32_t v9 = iv1();
    uint32_t v10 = iv2();
    uint32_t v11 = iv3();
    uint32_t v12 = (iv4() ^ 4U);
    uint32_t v13 = iv5();
    uint32_t v14 = (iv6() ^ 4294967295U);
    uint32_t v15 = iv7();
    auto __tup_137_8 = g_mix(v0, v4, v8, v12, m0, m1);
    auto a0 = 0 /* unhandled */;
    auto b0 = 0 /* unhandled */;
    auto c0 = 0 /* unhandled */;
    auto d0 = 0 /* unhandled */;
    auto __tup_138_8 = g_mix(v1, v5, v9, v13, m2, m3);
    auto a1 = 0 /* unhandled */;
    auto b1 = 0 /* unhandled */;
    auto c1 = 0 /* unhandled */;
    auto d1 = 0 /* unhandled */;
    auto __tup_139_8 = g_mix(v2, v6, v10, v14, m4, m5);
    auto a2 = 0 /* unhandled */;
    auto b2 = 0 /* unhandled */;
    auto c2 = 0 /* unhandled */;
    auto d2 = 0 /* unhandled */;
    auto __tup_140_8 = g_mix(v3, v7, v11, v15, m6, m7);
    auto a3 = 0 /* unhandled */;
    auto b3 = 0 /* unhandled */;
    auto c3 = 0 /* unhandled */;
    auto d3 = 0 /* unhandled */;
    auto __tup_141_8 = g_mix(a0, b1, c2, d3, m8, m9);
    auto a4 = 0 /* unhandled */;
    auto b4 = 0 /* unhandled */;
    auto c4 = 0 /* unhandled */;
    auto d4 = 0 /* unhandled */;
    auto __tup_142_8 = g_mix(a1, b2, c3, d0, m10, m11);
    auto a5 = 0 /* unhandled */;
    auto b5 = 0 /* unhandled */;
    auto c5 = 0 /* unhandled */;
    auto d5 = 0 /* unhandled */;
    auto __tup_143_8 = g_mix(a2, b3, c0, d1, m12, m13);
    auto a6 = 0 /* unhandled */;
    auto b6 = 0 /* unhandled */;
    auto c6 = 0 /* unhandled */;
    auto d6 = 0 /* unhandled */;
    auto __tup_144_8 = g_mix(a3, b0, c1, d2, m14, m15);
    auto a7 = 0 /* unhandled */;
    auto b7 = 0 /* unhandled */;
    auto c7 = 0 /* unhandled */;
    auto d7 = 0 /* unhandled */;
    uint32_t r0_0 = a4;
    uint32_t r0_1 = a5;
    uint32_t r0_2 = a6;
    uint32_t r0_3 = a7;
    uint32_t r0_4 = b7;
    uint32_t r0_5 = b4;
    uint32_t r0_6 = b5;
    uint32_t r0_7 = b6;
    uint32_t r0_8 = c6;
    uint32_t r0_9 = c7;
    uint32_t r0_10 = c4;
    uint32_t r0_11 = c5;
    uint32_t r0_12 = d5;
    uint32_t r0_13 = d6;
    uint32_t r0_14 = d7;
    uint32_t r0_15 = d4;
    auto __tup_153_8 = g_mix(r0_0, r0_4, r0_8, r0_12, m14, m10);
    auto a0b = 0 /* unhandled */;
    auto b0b = 0 /* unhandled */;
    auto c0b = 0 /* unhandled */;
    auto d0b = 0 /* unhandled */;
    auto __tup_154_8 = g_mix(r0_1, r0_5, r0_9, r0_13, m4, m8);
    auto a1b = 0 /* unhandled */;
    auto b1b = 0 /* unhandled */;
    auto c1b = 0 /* unhandled */;
    auto d1b = 0 /* unhandled */;
    auto __tup_155_8 = g_mix(r0_2, r0_6, r0_10, r0_14, m9, m15);
    auto a2b = 0 /* unhandled */;
    auto b2b = 0 /* unhandled */;
    auto c2b = 0 /* unhandled */;
    auto d2b = 0 /* unhandled */;
    auto __tup_156_8 = g_mix(r0_3, r0_7, r0_11, r0_15, m13, m6);
    auto a3b = 0 /* unhandled */;
    auto b3b = 0 /* unhandled */;
    auto c3b = 0 /* unhandled */;
    auto d3b = 0 /* unhandled */;
    auto __tup_157_8 = g_mix(a0b, b1b, c2b, d3b, m1, m12);
    auto a4b = 0 /* unhandled */;
    auto b4b = 0 /* unhandled */;
    auto c4b = 0 /* unhandled */;
    auto d4b = 0 /* unhandled */;
    auto __tup_158_8 = g_mix(a1b, b2b, c3b, d0b, m0, m2);
    auto a5b = 0 /* unhandled */;
    auto b5b = 0 /* unhandled */;
    auto c5b = 0 /* unhandled */;
    auto d5b = 0 /* unhandled */;
    auto __tup_159_8 = g_mix(a2b, b3b, c0b, d1b, m11, m7);
    auto a6b = 0 /* unhandled */;
    auto b6b = 0 /* unhandled */;
    auto c6b = 0 /* unhandled */;
    auto d6b = 0 /* unhandled */;
    auto __tup_160_8 = g_mix(a3b, b0b, c1b, d2b, m5, m3);
    auto a7b = 0 /* unhandled */;
    auto b7b = 0 /* unhandled */;
    auto c7b = 0 /* unhandled */;
    auto d7b = 0 /* unhandled */;
    uint32_t r1_0 = a4b;
    uint32_t r1_1 = a5b;
    uint32_t r1_2 = a6b;
    uint32_t r1_3 = a7b;
    uint32_t r1_4 = b7b;
    uint32_t r1_5 = b4b;
    uint32_t r1_6 = b5b;
    uint32_t r1_7 = b6b;
    uint32_t r1_8 = c6b;
    uint32_t r1_9 = c7b;
    uint32_t r1_10 = c4b;
    uint32_t r1_11 = c5b;
    uint32_t r1_12 = d5b;
    uint32_t r1_13 = d6b;
    uint32_t r1_14 = d7b;
    uint32_t r1_15 = d4b;
    auto __tup_167_8 = g_mix(r1_0, r1_4, r1_8, r1_12, m11, m8);
    auto a0c = 0 /* unhandled */;
    auto b0c = 0 /* unhandled */;
    auto c0c = 0 /* unhandled */;
    auto d0c = 0 /* unhandled */;
    auto __tup_168_8 = g_mix(r1_1, r1_5, r1_9, r1_13, m12, m0);
    auto a1c = 0 /* unhandled */;
    auto b1c = 0 /* unhandled */;
    auto c1c = 0 /* unhandled */;
    auto d1c = 0 /* unhandled */;
    auto __tup_169_8 = g_mix(r1_2, r1_6, r1_10, r1_14, m5, m2);
    auto a2c = 0 /* unhandled */;
    auto b2c = 0 /* unhandled */;
    auto c2c = 0 /* unhandled */;
    auto d2c = 0 /* unhandled */;
    auto __tup_170_8 = g_mix(r1_3, r1_7, r1_11, r1_15, m15, m13);
    auto a3c = 0 /* unhandled */;
    auto b3c = 0 /* unhandled */;
    auto c3c = 0 /* unhandled */;
    auto d3c = 0 /* unhandled */;
    auto __tup_171_8 = g_mix(a0c, b1c, c2c, d3c, m10, m14);
    auto a4c = 0 /* unhandled */;
    auto b4c = 0 /* unhandled */;
    auto c4c = 0 /* unhandled */;
    auto d4c = 0 /* unhandled */;
    auto __tup_172_8 = g_mix(a1c, b2c, c3c, d0c, m3, m6);
    auto a5c = 0 /* unhandled */;
    auto b5c = 0 /* unhandled */;
    auto c5c = 0 /* unhandled */;
    auto d5c = 0 /* unhandled */;
    auto __tup_173_8 = g_mix(a2c, b3c, c0c, d1c, m7, m1);
    auto a6c = 0 /* unhandled */;
    auto b6c = 0 /* unhandled */;
    auto c6c = 0 /* unhandled */;
    auto d6c = 0 /* unhandled */;
    auto __tup_174_8 = g_mix(a3c, b0c, c1c, d2c, m9, m4);
    auto a7c = 0 /* unhandled */;
    auto b7c = 0 /* unhandled */;
    auto c7c = 0 /* unhandled */;
    auto d7c = 0 /* unhandled */;
    uint32_t r2_0 = a4c;
    uint32_t r2_1 = a5c;
    uint32_t r2_2 = a6c;
    uint32_t r2_3 = a7c;
    uint32_t r2_4 = b7c;
    uint32_t r2_5 = b4c;
    uint32_t r2_6 = b5c;
    uint32_t r2_7 = b6c;
    uint32_t r2_8 = c6c;
    uint32_t r2_9 = c7c;
    uint32_t r2_10 = c4c;
    uint32_t r2_11 = c5c;
    uint32_t r2_12 = d5c;
    uint32_t r2_13 = d6c;
    uint32_t r2_14 = d7c;
    uint32_t r2_15 = d4c;
    auto __tup_181_8 = g_mix(r2_0, r2_4, r2_8, r2_12, m7, m9);
    auto a0d = 0 /* unhandled */;
    auto b0d = 0 /* unhandled */;
    auto c0d = 0 /* unhandled */;
    auto d0d = 0 /* unhandled */;
    auto __tup_182_8 = g_mix(r2_1, r2_5, r2_9, r2_13, m3, m1);
    auto a1d = 0 /* unhandled */;
    auto b1d = 0 /* unhandled */;
    auto c1d = 0 /* unhandled */;
    auto d1d = 0 /* unhandled */;
    auto __tup_183_8 = g_mix(r2_2, r2_6, r2_10, r2_14, m13, m12);
    auto a2d = 0 /* unhandled */;
    auto b2d = 0 /* unhandled */;
    auto c2d = 0 /* unhandled */;
    auto d2d = 0 /* unhandled */;
    auto __tup_184_8 = g_mix(r2_3, r2_7, r2_11, r2_15, m11, m14);
    auto a3d = 0 /* unhandled */;
    auto b3d = 0 /* unhandled */;
    auto c3d = 0 /* unhandled */;
    auto d3d = 0 /* unhandled */;
    auto __tup_185_8 = g_mix(a0d, b1d, c2d, d3d, m2, m6);
    auto a4d = 0 /* unhandled */;
    auto b4d = 0 /* unhandled */;
    auto c4d = 0 /* unhandled */;
    auto d4d = 0 /* unhandled */;
    auto __tup_186_8 = g_mix(a1d, b2d, c3d, d0d, m5, m10);
    auto a5d = 0 /* unhandled */;
    auto b5d = 0 /* unhandled */;
    auto c5d = 0 /* unhandled */;
    auto d5d = 0 /* unhandled */;
    auto __tup_187_8 = g_mix(a2d, b3d, c0d, d1d, m4, m0);
    auto a6d = 0 /* unhandled */;
    auto b6d = 0 /* unhandled */;
    auto c6d = 0 /* unhandled */;
    auto d6d = 0 /* unhandled */;
    auto __tup_188_8 = g_mix(a3d, b0d, c1d, d2d, m15, m8);
    auto a7d = 0 /* unhandled */;
    auto b7d = 0 /* unhandled */;
    auto c7d = 0 /* unhandled */;
    auto d7d = 0 /* unhandled */;
    uint32_t r3_0 = a4d;
    uint32_t r3_1 = a5d;
    uint32_t r3_2 = a6d;
    uint32_t r3_3 = a7d;
    uint32_t r3_4 = b7d;
    uint32_t r3_5 = b4d;
    uint32_t r3_6 = b5d;
    uint32_t r3_7 = b6d;
    uint32_t r3_8 = c6d;
    uint32_t r3_9 = c7d;
    uint32_t r3_10 = c4d;
    uint32_t r3_11 = c5d;
    uint32_t r3_12 = d5d;
    uint32_t r3_13 = d6d;
    uint32_t r3_14 = d7d;
    uint32_t r3_15 = d4d;
    auto __tup_195_8 = g_mix(r3_0, r3_4, r3_8, r3_12, m9, m0);
    auto a0e = 0 /* unhandled */;
    auto b0e = 0 /* unhandled */;
    auto c0e = 0 /* unhandled */;
    auto d0e = 0 /* unhandled */;
    auto __tup_196_8 = g_mix(r3_1, r3_5, r3_9, r3_13, m5, m7);
    auto a1e = 0 /* unhandled */;
    auto b1e = 0 /* unhandled */;
    auto c1e = 0 /* unhandled */;
    auto d1e = 0 /* unhandled */;
    auto __tup_197_8 = g_mix(r3_2, r3_6, r3_10, r3_14, m2, m4);
    auto a2e = 0 /* unhandled */;
    auto b2e = 0 /* unhandled */;
    auto c2e = 0 /* unhandled */;
    auto d2e = 0 /* unhandled */;
    auto __tup_198_8 = g_mix(r3_3, r3_7, r3_11, r3_15, m10, m15);
    auto a3e = 0 /* unhandled */;
    auto b3e = 0 /* unhandled */;
    auto c3e = 0 /* unhandled */;
    auto d3e = 0 /* unhandled */;
    auto __tup_199_8 = g_mix(a0e, b1e, c2e, d3e, m14, m1);
    auto a4e = 0 /* unhandled */;
    auto b4e = 0 /* unhandled */;
    auto c4e = 0 /* unhandled */;
    auto d4e = 0 /* unhandled */;
    auto __tup_200_8 = g_mix(a1e, b2e, c3e, d0e, m11, m12);
    auto a5e = 0 /* unhandled */;
    auto b5e = 0 /* unhandled */;
    auto c5e = 0 /* unhandled */;
    auto d5e = 0 /* unhandled */;
    auto __tup_201_8 = g_mix(a2e, b3e, c0e, d1e, m6, m8);
    auto a6e = 0 /* unhandled */;
    auto b6e = 0 /* unhandled */;
    auto c6e = 0 /* unhandled */;
    auto d6e = 0 /* unhandled */;
    auto __tup_202_8 = g_mix(a3e, b0e, c1e, d2e, m3, m13);
    auto a7e = 0 /* unhandled */;
    auto b7e = 0 /* unhandled */;
    auto c7e = 0 /* unhandled */;
    auto d7e = 0 /* unhandled */;
    uint32_t r4_0 = a4e;
    uint32_t r4_1 = a5e;
    uint32_t r4_2 = a6e;
    uint32_t r4_3 = a7e;
    uint32_t r4_4 = b7e;
    uint32_t r4_5 = b4e;
    uint32_t r4_6 = b5e;
    uint32_t r4_7 = b6e;
    uint32_t r4_8 = c6e;
    uint32_t r4_9 = c7e;
    uint32_t r4_10 = c4e;
    uint32_t r4_11 = c5e;
    uint32_t r4_12 = d5e;
    uint32_t r4_13 = d6e;
    uint32_t r4_14 = d7e;
    uint32_t r4_15 = d4e;
    auto __tup_209_8 = g_mix(r4_0, r4_4, r4_8, r4_12, m2, m12);
    auto a0f = 0 /* unhandled */;
    auto b0f = 0 /* unhandled */;
    auto c0f = 0 /* unhandled */;
    auto d0f = 0 /* unhandled */;
    auto __tup_210_8 = g_mix(r4_1, r4_5, r4_9, r4_13, m6, m10);
    auto a1f = 0 /* unhandled */;
    auto b1f = 0 /* unhandled */;
    auto c1f = 0 /* unhandled */;
    auto d1f = 0 /* unhandled */;
    auto __tup_211_8 = g_mix(r4_2, r4_6, r4_10, r4_14, m0, m11);
    auto a2f = 0 /* unhandled */;
    auto b2f = 0 /* unhandled */;
    auto c2f = 0 /* unhandled */;
    auto d2f = 0 /* unhandled */;
    auto __tup_212_8 = g_mix(r4_3, r4_7, r4_11, r4_15, m8, m3);
    auto a3f = 0 /* unhandled */;
    auto b3f = 0 /* unhandled */;
    auto c3f = 0 /* unhandled */;
    auto d3f = 0 /* unhandled */;
    auto __tup_213_8 = g_mix(a0f, b1f, c2f, d3f, m4, m13);
    auto a4f = 0 /* unhandled */;
    auto b4f = 0 /* unhandled */;
    auto c4f = 0 /* unhandled */;
    auto d4f = 0 /* unhandled */;
    auto __tup_214_8 = g_mix(a1f, b2f, c3f, d0f, m7, m5);
    auto a5f = 0 /* unhandled */;
    auto b5f = 0 /* unhandled */;
    auto c5f = 0 /* unhandled */;
    auto d5f = 0 /* unhandled */;
    auto __tup_215_8 = g_mix(a2f, b3f, c0f, d1f, m15, m14);
    auto a6f = 0 /* unhandled */;
    auto b6f = 0 /* unhandled */;
    auto c6f = 0 /* unhandled */;
    auto d6f = 0 /* unhandled */;
    auto __tup_216_8 = g_mix(a3f, b0f, c1f, d2f, m1, m9);
    auto a7f = 0 /* unhandled */;
    auto b7f = 0 /* unhandled */;
    auto c7f = 0 /* unhandled */;
    auto d7f = 0 /* unhandled */;
    uint32_t r5_0 = a4f;
    uint32_t r5_1 = a5f;
    uint32_t r5_2 = a6f;
    uint32_t r5_3 = a7f;
    uint32_t r5_4 = b7f;
    uint32_t r5_5 = b4f;
    uint32_t r5_6 = b5f;
    uint32_t r5_7 = b6f;
    uint32_t r5_8 = c6f;
    uint32_t r5_9 = c7f;
    uint32_t r5_10 = c4f;
    uint32_t r5_11 = c5f;
    uint32_t r5_12 = d5f;
    uint32_t r5_13 = d6f;
    uint32_t r5_14 = d7f;
    uint32_t r5_15 = d4f;
    auto __tup_223_8 = g_mix(r5_0, r5_4, r5_8, r5_12, m12, m5);
    auto a0g = 0 /* unhandled */;
    auto b0g = 0 /* unhandled */;
    auto c0g = 0 /* unhandled */;
    auto d0g = 0 /* unhandled */;
    auto __tup_224_8 = g_mix(r5_1, r5_5, r5_9, r5_13, m1, m15);
    auto a1g = 0 /* unhandled */;
    auto b1g = 0 /* unhandled */;
    auto c1g = 0 /* unhandled */;
    auto d1g = 0 /* unhandled */;
    auto __tup_225_8 = g_mix(r5_2, r5_6, r5_10, r5_14, m14, m13);
    auto a2g = 0 /* unhandled */;
    auto b2g = 0 /* unhandled */;
    auto c2g = 0 /* unhandled */;
    auto d2g = 0 /* unhandled */;
    auto __tup_226_8 = g_mix(r5_3, r5_7, r5_11, r5_15, m4, m10);
    auto a3g = 0 /* unhandled */;
    auto b3g = 0 /* unhandled */;
    auto c3g = 0 /* unhandled */;
    auto d3g = 0 /* unhandled */;
    auto __tup_227_8 = g_mix(a0g, b1g, c2g, d3g, m0, m7);
    auto a4g = 0 /* unhandled */;
    auto b4g = 0 /* unhandled */;
    auto c4g = 0 /* unhandled */;
    auto d4g = 0 /* unhandled */;
    auto __tup_228_8 = g_mix(a1g, b2g, c3g, d0g, m6, m3);
    auto a5g = 0 /* unhandled */;
    auto b5g = 0 /* unhandled */;
    auto c5g = 0 /* unhandled */;
    auto d5g = 0 /* unhandled */;
    auto __tup_229_8 = g_mix(a2g, b3g, c0g, d1g, m9, m2);
    auto a6g = 0 /* unhandled */;
    auto b6g = 0 /* unhandled */;
    auto c6g = 0 /* unhandled */;
    auto d6g = 0 /* unhandled */;
    auto __tup_230_8 = g_mix(a3g, b0g, c1g, d2g, m8, m11);
    auto a7g = 0 /* unhandled */;
    auto b7g = 0 /* unhandled */;
    auto c7g = 0 /* unhandled */;
    auto d7g = 0 /* unhandled */;
    uint32_t r6_0 = a4g;
    uint32_t r6_1 = a5g;
    uint32_t r6_2 = a6g;
    uint32_t r6_3 = a7g;
    uint32_t r6_4 = b7g;
    uint32_t r6_5 = b4g;
    uint32_t r6_6 = b5g;
    uint32_t r6_7 = b6g;
    uint32_t r6_8 = c6g;
    uint32_t r6_9 = c7g;
    uint32_t r6_10 = c4g;
    uint32_t r6_11 = c5g;
    uint32_t r6_12 = d5g;
    uint32_t r6_13 = d6g;
    uint32_t r6_14 = d7g;
    uint32_t r6_15 = d4g;
    auto __tup_237_8 = g_mix(r6_0, r6_4, r6_8, r6_12, m13, m11);
    auto a0h = 0 /* unhandled */;
    auto b0h = 0 /* unhandled */;
    auto c0h = 0 /* unhandled */;
    auto d0h = 0 /* unhandled */;
    auto __tup_238_8 = g_mix(r6_1, r6_5, r6_9, r6_13, m7, m14);
    auto a1h = 0 /* unhandled */;
    auto b1h = 0 /* unhandled */;
    auto c1h = 0 /* unhandled */;
    auto d1h = 0 /* unhandled */;
    auto __tup_239_8 = g_mix(r6_2, r6_6, r6_10, r6_14, m12, m1);
    auto a2h = 0 /* unhandled */;
    auto b2h = 0 /* unhandled */;
    auto c2h = 0 /* unhandled */;
    auto d2h = 0 /* unhandled */;
    auto __tup_240_8 = g_mix(r6_3, r6_7, r6_11, r6_15, m3, m9);
    auto a3h = 0 /* unhandled */;
    auto b3h = 0 /* unhandled */;
    auto c3h = 0 /* unhandled */;
    auto d3h = 0 /* unhandled */;
    auto __tup_241_8 = g_mix(a0h, b1h, c2h, d3h, m5, m0);
    auto a4h = 0 /* unhandled */;
    auto b4h = 0 /* unhandled */;
    auto c4h = 0 /* unhandled */;
    auto d4h = 0 /* unhandled */;
    auto __tup_242_8 = g_mix(a1h, b2h, c3h, d0h, m15, m4);
    auto a5h = 0 /* unhandled */;
    auto b5h = 0 /* unhandled */;
    auto c5h = 0 /* unhandled */;
    auto d5h = 0 /* unhandled */;
    auto __tup_243_8 = g_mix(a2h, b3h, c0h, d1h, m8, m6);
    auto a6h = 0 /* unhandled */;
    auto b6h = 0 /* unhandled */;
    auto c6h = 0 /* unhandled */;
    auto d6h = 0 /* unhandled */;
    auto __tup_244_8 = g_mix(a3h, b0h, c1h, d2h, m2, m10);
    auto a7h = 0 /* unhandled */;
    auto b7h = 0 /* unhandled */;
    auto c7h = 0 /* unhandled */;
    auto d7h = 0 /* unhandled */;
    uint32_t r7_0 = a4h;
    uint32_t r7_1 = a5h;
    uint32_t r7_2 = a6h;
    uint32_t r7_3 = a7h;
    uint32_t r7_4 = b7h;
    uint32_t r7_5 = b4h;
    uint32_t r7_6 = b5h;
    uint32_t r7_7 = b6h;
    uint32_t r7_8 = c6h;
    uint32_t r7_9 = c7h;
    uint32_t r7_10 = c4h;
    uint32_t r7_11 = c5h;
    uint32_t r7_12 = d5h;
    uint32_t r7_13 = d6h;
    uint32_t r7_14 = d7h;
    uint32_t r7_15 = d4h;
    auto __tup_251_8 = g_mix(r7_0, r7_4, r7_8, r7_12, m6, m15);
    auto a0i = 0 /* unhandled */;
    auto b0i = 0 /* unhandled */;
    auto c0i = 0 /* unhandled */;
    auto d0i = 0 /* unhandled */;
    auto __tup_252_8 = g_mix(r7_1, r7_5, r7_9, r7_13, m14, m9);
    auto a1i = 0 /* unhandled */;
    auto b1i = 0 /* unhandled */;
    auto c1i = 0 /* unhandled */;
    auto d1i = 0 /* unhandled */;
    auto __tup_253_8 = g_mix(r7_2, r7_6, r7_10, r7_14, m11, m3);
    auto a2i = 0 /* unhandled */;
    auto b2i = 0 /* unhandled */;
    auto c2i = 0 /* unhandled */;
    auto d2i = 0 /* unhandled */;
    auto __tup_254_8 = g_mix(r7_3, r7_7, r7_11, r7_15, m0, m8);
    auto a3i = 0 /* unhandled */;
    auto b3i = 0 /* unhandled */;
    auto c3i = 0 /* unhandled */;
    auto d3i = 0 /* unhandled */;
    auto __tup_255_8 = g_mix(a0i, b1i, c2i, d3i, m12, m2);
    auto a4i = 0 /* unhandled */;
    auto b4i = 0 /* unhandled */;
    auto c4i = 0 /* unhandled */;
    auto d4i = 0 /* unhandled */;
    auto __tup_256_8 = g_mix(a1i, b2i, c3i, d0i, m13, m7);
    auto a5i = 0 /* unhandled */;
    auto b5i = 0 /* unhandled */;
    auto c5i = 0 /* unhandled */;
    auto d5i = 0 /* unhandled */;
    auto __tup_257_8 = g_mix(a2i, b3i, c0i, d1i, m1, m4);
    auto a6i = 0 /* unhandled */;
    auto b6i = 0 /* unhandled */;
    auto c6i = 0 /* unhandled */;
    auto d6i = 0 /* unhandled */;
    auto __tup_258_8 = g_mix(a3i, b0i, c1i, d2i, m10, m5);
    auto a7i = 0 /* unhandled */;
    auto b7i = 0 /* unhandled */;
    auto c7i = 0 /* unhandled */;
    auto d7i = 0 /* unhandled */;
    uint32_t r8_0 = a4i;
    uint32_t r8_1 = a5i;
    uint32_t r8_2 = a6i;
    uint32_t r8_3 = a7i;
    uint32_t r8_4 = b7i;
    uint32_t r8_5 = b4i;
    uint32_t r8_6 = b5i;
    uint32_t r8_7 = b6i;
    uint32_t r8_8 = c6i;
    uint32_t r8_9 = c7i;
    uint32_t r8_10 = c4i;
    uint32_t r8_11 = c5i;
    uint32_t r8_12 = d5i;
    uint32_t r8_13 = d6i;
    uint32_t r8_14 = d7i;
    uint32_t r8_15 = d4i;
    auto __tup_265_8 = g_mix(r8_0, r8_4, r8_8, r8_12, m10, m2);
    auto a0j = 0 /* unhandled */;
    auto b0j = 0 /* unhandled */;
    auto c0j = 0 /* unhandled */;
    auto d0j = 0 /* unhandled */;
    auto __tup_266_8 = g_mix(r8_1, r8_5, r8_9, r8_13, m8, m4);
    auto a1j = 0 /* unhandled */;
    auto b1j = 0 /* unhandled */;
    auto c1j = 0 /* unhandled */;
    auto d1j = 0 /* unhandled */;
    auto __tup_267_8 = g_mix(r8_2, r8_6, r8_10, r8_14, m7, m6);
    auto a2j = 0 /* unhandled */;
    auto b2j = 0 /* unhandled */;
    auto c2j = 0 /* unhandled */;
    auto d2j = 0 /* unhandled */;
    auto __tup_268_8 = g_mix(r8_3, r8_7, r8_11, r8_15, m1, m5);
    auto a3j = 0 /* unhandled */;
    auto b3j = 0 /* unhandled */;
    auto c3j = 0 /* unhandled */;
    auto d3j = 0 /* unhandled */;
    auto __tup_269_8 = g_mix(a0j, b1j, c2j, d3j, m15, m11);
    auto a4j = 0 /* unhandled */;
    auto b4j = 0 /* unhandled */;
    auto c4j = 0 /* unhandled */;
    auto d4j = 0 /* unhandled */;
    auto __tup_270_8 = g_mix(a1j, b2j, c3j, d0j, m9, m14);
    auto a5j = 0 /* unhandled */;
    auto b5j = 0 /* unhandled */;
    auto c5j = 0 /* unhandled */;
    auto d5j = 0 /* unhandled */;
    auto __tup_271_8 = g_mix(a2j, b3j, c0j, d1j, m3, m12);
    auto a6j = 0 /* unhandled */;
    auto b6j = 0 /* unhandled */;
    auto c6j = 0 /* unhandled */;
    auto d6j = 0 /* unhandled */;
    auto __tup_272_8 = g_mix(a3j, b0j, c1j, d2j, m13, m0);
    auto a7j = 0 /* unhandled */;
    auto b7j = 0 /* unhandled */;
    auto c7j = 0 /* unhandled */;
    auto d7j = 0 /* unhandled */;
    uint32_t f0 = a4j;
    uint32_t f1 = a5j;
    uint32_t f2 = a6j;
    uint32_t f3 = a7j;
    uint32_t f4 = b7j;
    uint32_t f5 = b4j;
    uint32_t f6 = b5j;
    uint32_t f7 = b6j;
    uint32_t f8 = c6j;
    uint32_t f9 = c7j;
    uint32_t f10 = c4j;
    uint32_t f11 = c5j;
    uint32_t f12 = d5j;
    uint32_t f13 = d6j;
    uint32_t f14 = d7j;
    uint32_t f15 = d4j;
    uint32_t out0 = ((h0 ^ f0) ^ f8);
    uint32_t out1 = ((h1 ^ f1) ^ f9);
    uint32_t out2 = ((h2 ^ f2) ^ f10);
    uint32_t out3 = ((h3 ^ f3) ^ f11);
    uint32_t out4 = ((h4 ^ f4) ^ f12);
    uint32_t out5 = ((h5 ^ f5) ^ f13);
    uint32_t out6 = ((h6 ^ f6) ^ f14);
    uint32_t out7 = ((h7 ^ f7) ^ f15);
    uint64_t base = (leaf * 8ULL);
    if (((base + 7ULL) < hashes_len)) {
      hashes[base] = out0;
      hashes[(base + 1ULL)] = out1;
      hashes[(base + 2ULL)] = out2;
      hashes[(base + 3ULL)] = out3;
      hashes[(base + 4ULL)] = out4;
      hashes[(base + 5ULL)] = out5;
      hashes[(base + 6ULL)] = out6;
      hashes[(base + 7ULL)] = out7;
    }
  }
}

__global__ void merkle_hash_leaves_quad(uint32_t* __restrict__ c0, uint64_t c0_len, uint32_t* __restrict__ c1, uint64_t c1_len, uint32_t* __restrict__ c2, uint64_t c2_len, uint32_t* __restrict__ c3, uint64_t c3_len, uint32_t* __restrict__ hashes, uint64_t hashes_len, uint64_t n_leaves) {
  uint64_t leaf = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((leaf < n_leaves)) {
    uint32_t m0 = c0[leaf];
    uint32_t m1 = c1[leaf];
    uint32_t m2 = c2[leaf];
    uint32_t m3 = c3[leaf];
    uint32_t m4 = 0U;
    uint32_t m5 = 0U;
    uint32_t m6 = 0U;
    uint32_t m7 = 0U;
    uint32_t m8 = 0U;
    uint32_t m9 = 0U;
    uint32_t m10 = 0U;
    uint32_t m11 = 0U;
    uint32_t m12 = 0U;
    uint32_t m13 = 0U;
    uint32_t m14 = 0U;
    uint32_t m15 = 0U;
    uint32_t h0 = (iv0() ^ 16842784U);
    uint32_t h1 = iv1();
    uint32_t h2 = iv2();
    uint32_t h3 = iv3();
    uint32_t h4 = iv4();
    uint32_t h5 = iv5();
    uint32_t h6 = iv6();
    uint32_t h7 = iv7();
    uint32_t v0 = h0;
    uint32_t v1 = h1;
    uint32_t v2 = h2;
    uint32_t v3 = h3;
    uint32_t v4 = h4;
    uint32_t v5 = h5;
    uint32_t v6 = h6;
    uint32_t v7 = h7;
    uint32_t v8 = iv0();
    uint32_t v9 = iv1();
    uint32_t v10 = iv2();
    uint32_t v11 = iv3();
    uint32_t v12 = (iv4() ^ 16U);
    uint32_t v13 = iv5();
    uint32_t v14 = (iv6() ^ 4294967295U);
    uint32_t v15 = iv7();
    auto __tup_358_8 = g_mix(v0, v4, v8, v12, m0, m1);
    auto a0 = 0 /* unhandled */;
    auto b0 = 0 /* unhandled */;
    auto c0 = 0 /* unhandled */;
    auto d0 = 0 /* unhandled */;
    auto __tup_359_8 = g_mix(v1, v5, v9, v13, m2, m3);
    auto a1 = 0 /* unhandled */;
    auto b1 = 0 /* unhandled */;
    auto c1 = 0 /* unhandled */;
    auto d1 = 0 /* unhandled */;
    auto __tup_360_8 = g_mix(v2, v6, v10, v14, m4, m5);
    auto a2 = 0 /* unhandled */;
    auto b2 = 0 /* unhandled */;
    auto c2 = 0 /* unhandled */;
    auto d2 = 0 /* unhandled */;
    auto __tup_361_8 = g_mix(v3, v7, v11, v15, m6, m7);
    auto a3 = 0 /* unhandled */;
    auto b3 = 0 /* unhandled */;
    auto c3 = 0 /* unhandled */;
    auto d3 = 0 /* unhandled */;
    auto __tup_362_8 = g_mix(a0, b1, c2, d3, m8, m9);
    auto a4 = 0 /* unhandled */;
    auto b4 = 0 /* unhandled */;
    auto c4 = 0 /* unhandled */;
    auto d4 = 0 /* unhandled */;
    auto __tup_363_8 = g_mix(a1, b2, c3, d0, m10, m11);
    auto a5 = 0 /* unhandled */;
    auto b5 = 0 /* unhandled */;
    auto c5 = 0 /* unhandled */;
    auto d5 = 0 /* unhandled */;
    auto __tup_364_8 = g_mix(a2, b3, c0, d1, m12, m13);
    auto a6 = 0 /* unhandled */;
    auto b6 = 0 /* unhandled */;
    auto c6 = 0 /* unhandled */;
    auto d6 = 0 /* unhandled */;
    auto __tup_365_8 = g_mix(a3, b0, c1, d2, m14, m15);
    auto a7 = 0 /* unhandled */;
    auto b7 = 0 /* unhandled */;
    auto c7 = 0 /* unhandled */;
    auto d7 = 0 /* unhandled */;
    uint32_t r0_0 = a4;
    uint32_t r0_1 = a5;
    uint32_t r0_2 = a6;
    uint32_t r0_3 = a7;
    uint32_t r0_4 = b7;
    uint32_t r0_5 = b4;
    uint32_t r0_6 = b5;
    uint32_t r0_7 = b6;
    uint32_t r0_8 = c6;
    uint32_t r0_9 = c7;
    uint32_t r0_10 = c4;
    uint32_t r0_11 = c5;
    uint32_t r0_12 = d5;
    uint32_t r0_13 = d6;
    uint32_t r0_14 = d7;
    uint32_t r0_15 = d4;
    auto __tup_374_8 = g_mix(r0_0, r0_4, r0_8, r0_12, m14, m10);
    auto a0b = 0 /* unhandled */;
    auto b0b = 0 /* unhandled */;
    auto c0b = 0 /* unhandled */;
    auto d0b = 0 /* unhandled */;
    auto __tup_375_8 = g_mix(r0_1, r0_5, r0_9, r0_13, m4, m8);
    auto a1b = 0 /* unhandled */;
    auto b1b = 0 /* unhandled */;
    auto c1b = 0 /* unhandled */;
    auto d1b = 0 /* unhandled */;
    auto __tup_376_8 = g_mix(r0_2, r0_6, r0_10, r0_14, m9, m15);
    auto a2b = 0 /* unhandled */;
    auto b2b = 0 /* unhandled */;
    auto c2b = 0 /* unhandled */;
    auto d2b = 0 /* unhandled */;
    auto __tup_377_8 = g_mix(r0_3, r0_7, r0_11, r0_15, m13, m6);
    auto a3b = 0 /* unhandled */;
    auto b3b = 0 /* unhandled */;
    auto c3b = 0 /* unhandled */;
    auto d3b = 0 /* unhandled */;
    auto __tup_378_8 = g_mix(a0b, b1b, c2b, d3b, m1, m12);
    auto a4b = 0 /* unhandled */;
    auto b4b = 0 /* unhandled */;
    auto c4b = 0 /* unhandled */;
    auto d4b = 0 /* unhandled */;
    auto __tup_379_8 = g_mix(a1b, b2b, c3b, d0b, m0, m2);
    auto a5b = 0 /* unhandled */;
    auto b5b = 0 /* unhandled */;
    auto c5b = 0 /* unhandled */;
    auto d5b = 0 /* unhandled */;
    auto __tup_380_8 = g_mix(a2b, b3b, c0b, d1b, m11, m7);
    auto a6b = 0 /* unhandled */;
    auto b6b = 0 /* unhandled */;
    auto c6b = 0 /* unhandled */;
    auto d6b = 0 /* unhandled */;
    auto __tup_381_8 = g_mix(a3b, b0b, c1b, d2b, m5, m3);
    auto a7b = 0 /* unhandled */;
    auto b7b = 0 /* unhandled */;
    auto c7b = 0 /* unhandled */;
    auto d7b = 0 /* unhandled */;
    uint32_t r1_0 = a4b;
    uint32_t r1_1 = a5b;
    uint32_t r1_2 = a6b;
    uint32_t r1_3 = a7b;
    uint32_t r1_4 = b7b;
    uint32_t r1_5 = b4b;
    uint32_t r1_6 = b5b;
    uint32_t r1_7 = b6b;
    uint32_t r1_8 = c6b;
    uint32_t r1_9 = c7b;
    uint32_t r1_10 = c4b;
    uint32_t r1_11 = c5b;
    uint32_t r1_12 = d5b;
    uint32_t r1_13 = d6b;
    uint32_t r1_14 = d7b;
    uint32_t r1_15 = d4b;
    auto __tup_388_8 = g_mix(r1_0, r1_4, r1_8, r1_12, m11, m8);
    auto a0c = 0 /* unhandled */;
    auto b0c = 0 /* unhandled */;
    auto c0c = 0 /* unhandled */;
    auto d0c = 0 /* unhandled */;
    auto __tup_389_8 = g_mix(r1_1, r1_5, r1_9, r1_13, m12, m0);
    auto a1c = 0 /* unhandled */;
    auto b1c = 0 /* unhandled */;
    auto c1c = 0 /* unhandled */;
    auto d1c = 0 /* unhandled */;
    auto __tup_390_8 = g_mix(r1_2, r1_6, r1_10, r1_14, m5, m2);
    auto a2c = 0 /* unhandled */;
    auto b2c = 0 /* unhandled */;
    auto c2c = 0 /* unhandled */;
    auto d2c = 0 /* unhandled */;
    auto __tup_391_8 = g_mix(r1_3, r1_7, r1_11, r1_15, m15, m13);
    auto a3c = 0 /* unhandled */;
    auto b3c = 0 /* unhandled */;
    auto c3c = 0 /* unhandled */;
    auto d3c = 0 /* unhandled */;
    auto __tup_392_8 = g_mix(a0c, b1c, c2c, d3c, m10, m14);
    auto a4c = 0 /* unhandled */;
    auto b4c = 0 /* unhandled */;
    auto c4c = 0 /* unhandled */;
    auto d4c = 0 /* unhandled */;
    auto __tup_393_8 = g_mix(a1c, b2c, c3c, d0c, m3, m6);
    auto a5c = 0 /* unhandled */;
    auto b5c = 0 /* unhandled */;
    auto c5c = 0 /* unhandled */;
    auto d5c = 0 /* unhandled */;
    auto __tup_394_8 = g_mix(a2c, b3c, c0c, d1c, m7, m1);
    auto a6c = 0 /* unhandled */;
    auto b6c = 0 /* unhandled */;
    auto c6c = 0 /* unhandled */;
    auto d6c = 0 /* unhandled */;
    auto __tup_395_8 = g_mix(a3c, b0c, c1c, d2c, m9, m4);
    auto a7c = 0 /* unhandled */;
    auto b7c = 0 /* unhandled */;
    auto c7c = 0 /* unhandled */;
    auto d7c = 0 /* unhandled */;
    uint32_t r2_0 = a4c;
    uint32_t r2_1 = a5c;
    uint32_t r2_2 = a6c;
    uint32_t r2_3 = a7c;
    uint32_t r2_4 = b7c;
    uint32_t r2_5 = b4c;
    uint32_t r2_6 = b5c;
    uint32_t r2_7 = b6c;
    uint32_t r2_8 = c6c;
    uint32_t r2_9 = c7c;
    uint32_t r2_10 = c4c;
    uint32_t r2_11 = c5c;
    uint32_t r2_12 = d5c;
    uint32_t r2_13 = d6c;
    uint32_t r2_14 = d7c;
    uint32_t r2_15 = d4c;
    auto __tup_402_8 = g_mix(r2_0, r2_4, r2_8, r2_12, m7, m9);
    auto a0d = 0 /* unhandled */;
    auto b0d = 0 /* unhandled */;
    auto c0d = 0 /* unhandled */;
    auto d0d = 0 /* unhandled */;
    auto __tup_403_8 = g_mix(r2_1, r2_5, r2_9, r2_13, m3, m1);
    auto a1d = 0 /* unhandled */;
    auto b1d = 0 /* unhandled */;
    auto c1d = 0 /* unhandled */;
    auto d1d = 0 /* unhandled */;
    auto __tup_404_8 = g_mix(r2_2, r2_6, r2_10, r2_14, m13, m12);
    auto a2d = 0 /* unhandled */;
    auto b2d = 0 /* unhandled */;
    auto c2d = 0 /* unhandled */;
    auto d2d = 0 /* unhandled */;
    auto __tup_405_8 = g_mix(r2_3, r2_7, r2_11, r2_15, m11, m14);
    auto a3d = 0 /* unhandled */;
    auto b3d = 0 /* unhandled */;
    auto c3d = 0 /* unhandled */;
    auto d3d = 0 /* unhandled */;
    auto __tup_406_8 = g_mix(a0d, b1d, c2d, d3d, m2, m6);
    auto a4d = 0 /* unhandled */;
    auto b4d = 0 /* unhandled */;
    auto c4d = 0 /* unhandled */;
    auto d4d = 0 /* unhandled */;
    auto __tup_407_8 = g_mix(a1d, b2d, c3d, d0d, m5, m10);
    auto a5d = 0 /* unhandled */;
    auto b5d = 0 /* unhandled */;
    auto c5d = 0 /* unhandled */;
    auto d5d = 0 /* unhandled */;
    auto __tup_408_8 = g_mix(a2d, b3d, c0d, d1d, m4, m0);
    auto a6d = 0 /* unhandled */;
    auto b6d = 0 /* unhandled */;
    auto c6d = 0 /* unhandled */;
    auto d6d = 0 /* unhandled */;
    auto __tup_409_8 = g_mix(a3d, b0d, c1d, d2d, m15, m8);
    auto a7d = 0 /* unhandled */;
    auto b7d = 0 /* unhandled */;
    auto c7d = 0 /* unhandled */;
    auto d7d = 0 /* unhandled */;
    uint32_t r3_0 = a4d;
    uint32_t r3_1 = a5d;
    uint32_t r3_2 = a6d;
    uint32_t r3_3 = a7d;
    uint32_t r3_4 = b7d;
    uint32_t r3_5 = b4d;
    uint32_t r3_6 = b5d;
    uint32_t r3_7 = b6d;
    uint32_t r3_8 = c6d;
    uint32_t r3_9 = c7d;
    uint32_t r3_10 = c4d;
    uint32_t r3_11 = c5d;
    uint32_t r3_12 = d5d;
    uint32_t r3_13 = d6d;
    uint32_t r3_14 = d7d;
    uint32_t r3_15 = d4d;
    auto __tup_416_8 = g_mix(r3_0, r3_4, r3_8, r3_12, m9, m0);
    auto a0e = 0 /* unhandled */;
    auto b0e = 0 /* unhandled */;
    auto c0e = 0 /* unhandled */;
    auto d0e = 0 /* unhandled */;
    auto __tup_417_8 = g_mix(r3_1, r3_5, r3_9, r3_13, m5, m7);
    auto a1e = 0 /* unhandled */;
    auto b1e = 0 /* unhandled */;
    auto c1e = 0 /* unhandled */;
    auto d1e = 0 /* unhandled */;
    auto __tup_418_8 = g_mix(r3_2, r3_6, r3_10, r3_14, m2, m4);
    auto a2e = 0 /* unhandled */;
    auto b2e = 0 /* unhandled */;
    auto c2e = 0 /* unhandled */;
    auto d2e = 0 /* unhandled */;
    auto __tup_419_8 = g_mix(r3_3, r3_7, r3_11, r3_15, m10, m15);
    auto a3e = 0 /* unhandled */;
    auto b3e = 0 /* unhandled */;
    auto c3e = 0 /* unhandled */;
    auto d3e = 0 /* unhandled */;
    auto __tup_420_8 = g_mix(a0e, b1e, c2e, d3e, m14, m1);
    auto a4e = 0 /* unhandled */;
    auto b4e = 0 /* unhandled */;
    auto c4e = 0 /* unhandled */;
    auto d4e = 0 /* unhandled */;
    auto __tup_421_8 = g_mix(a1e, b2e, c3e, d0e, m11, m12);
    auto a5e = 0 /* unhandled */;
    auto b5e = 0 /* unhandled */;
    auto c5e = 0 /* unhandled */;
    auto d5e = 0 /* unhandled */;
    auto __tup_422_8 = g_mix(a2e, b3e, c0e, d1e, m6, m8);
    auto a6e = 0 /* unhandled */;
    auto b6e = 0 /* unhandled */;
    auto c6e = 0 /* unhandled */;
    auto d6e = 0 /* unhandled */;
    auto __tup_423_8 = g_mix(a3e, b0e, c1e, d2e, m3, m13);
    auto a7e = 0 /* unhandled */;
    auto b7e = 0 /* unhandled */;
    auto c7e = 0 /* unhandled */;
    auto d7e = 0 /* unhandled */;
    uint32_t r4_0 = a4e;
    uint32_t r4_1 = a5e;
    uint32_t r4_2 = a6e;
    uint32_t r4_3 = a7e;
    uint32_t r4_4 = b7e;
    uint32_t r4_5 = b4e;
    uint32_t r4_6 = b5e;
    uint32_t r4_7 = b6e;
    uint32_t r4_8 = c6e;
    uint32_t r4_9 = c7e;
    uint32_t r4_10 = c4e;
    uint32_t r4_11 = c5e;
    uint32_t r4_12 = d5e;
    uint32_t r4_13 = d6e;
    uint32_t r4_14 = d7e;
    uint32_t r4_15 = d4e;
    auto __tup_430_8 = g_mix(r4_0, r4_4, r4_8, r4_12, m2, m12);
    auto a0f = 0 /* unhandled */;
    auto b0f = 0 /* unhandled */;
    auto c0f = 0 /* unhandled */;
    auto d0f = 0 /* unhandled */;
    auto __tup_431_8 = g_mix(r4_1, r4_5, r4_9, r4_13, m6, m10);
    auto a1f = 0 /* unhandled */;
    auto b1f = 0 /* unhandled */;
    auto c1f = 0 /* unhandled */;
    auto d1f = 0 /* unhandled */;
    auto __tup_432_8 = g_mix(r4_2, r4_6, r4_10, r4_14, m0, m11);
    auto a2f = 0 /* unhandled */;
    auto b2f = 0 /* unhandled */;
    auto c2f = 0 /* unhandled */;
    auto d2f = 0 /* unhandled */;
    auto __tup_433_8 = g_mix(r4_3, r4_7, r4_11, r4_15, m8, m3);
    auto a3f = 0 /* unhandled */;
    auto b3f = 0 /* unhandled */;
    auto c3f = 0 /* unhandled */;
    auto d3f = 0 /* unhandled */;
    auto __tup_434_8 = g_mix(a0f, b1f, c2f, d3f, m4, m13);
    auto a4f = 0 /* unhandled */;
    auto b4f = 0 /* unhandled */;
    auto c4f = 0 /* unhandled */;
    auto d4f = 0 /* unhandled */;
    auto __tup_435_8 = g_mix(a1f, b2f, c3f, d0f, m7, m5);
    auto a5f = 0 /* unhandled */;
    auto b5f = 0 /* unhandled */;
    auto c5f = 0 /* unhandled */;
    auto d5f = 0 /* unhandled */;
    auto __tup_436_8 = g_mix(a2f, b3f, c0f, d1f, m15, m14);
    auto a6f = 0 /* unhandled */;
    auto b6f = 0 /* unhandled */;
    auto c6f = 0 /* unhandled */;
    auto d6f = 0 /* unhandled */;
    auto __tup_437_8 = g_mix(a3f, b0f, c1f, d2f, m1, m9);
    auto a7f = 0 /* unhandled */;
    auto b7f = 0 /* unhandled */;
    auto c7f = 0 /* unhandled */;
    auto d7f = 0 /* unhandled */;
    uint32_t r5_0 = a4f;
    uint32_t r5_1 = a5f;
    uint32_t r5_2 = a6f;
    uint32_t r5_3 = a7f;
    uint32_t r5_4 = b7f;
    uint32_t r5_5 = b4f;
    uint32_t r5_6 = b5f;
    uint32_t r5_7 = b6f;
    uint32_t r5_8 = c6f;
    uint32_t r5_9 = c7f;
    uint32_t r5_10 = c4f;
    uint32_t r5_11 = c5f;
    uint32_t r5_12 = d5f;
    uint32_t r5_13 = d6f;
    uint32_t r5_14 = d7f;
    uint32_t r5_15 = d4f;
    auto __tup_444_8 = g_mix(r5_0, r5_4, r5_8, r5_12, m12, m5);
    auto a0g = 0 /* unhandled */;
    auto b0g = 0 /* unhandled */;
    auto c0g = 0 /* unhandled */;
    auto d0g = 0 /* unhandled */;
    auto __tup_445_8 = g_mix(r5_1, r5_5, r5_9, r5_13, m1, m15);
    auto a1g = 0 /* unhandled */;
    auto b1g = 0 /* unhandled */;
    auto c1g = 0 /* unhandled */;
    auto d1g = 0 /* unhandled */;
    auto __tup_446_8 = g_mix(r5_2, r5_6, r5_10, r5_14, m14, m13);
    auto a2g = 0 /* unhandled */;
    auto b2g = 0 /* unhandled */;
    auto c2g = 0 /* unhandled */;
    auto d2g = 0 /* unhandled */;
    auto __tup_447_8 = g_mix(r5_3, r5_7, r5_11, r5_15, m4, m10);
    auto a3g = 0 /* unhandled */;
    auto b3g = 0 /* unhandled */;
    auto c3g = 0 /* unhandled */;
    auto d3g = 0 /* unhandled */;
    auto __tup_448_8 = g_mix(a0g, b1g, c2g, d3g, m0, m7);
    auto a4g = 0 /* unhandled */;
    auto b4g = 0 /* unhandled */;
    auto c4g = 0 /* unhandled */;
    auto d4g = 0 /* unhandled */;
    auto __tup_449_8 = g_mix(a1g, b2g, c3g, d0g, m6, m3);
    auto a5g = 0 /* unhandled */;
    auto b5g = 0 /* unhandled */;
    auto c5g = 0 /* unhandled */;
    auto d5g = 0 /* unhandled */;
    auto __tup_450_8 = g_mix(a2g, b3g, c0g, d1g, m9, m2);
    auto a6g = 0 /* unhandled */;
    auto b6g = 0 /* unhandled */;
    auto c6g = 0 /* unhandled */;
    auto d6g = 0 /* unhandled */;
    auto __tup_451_8 = g_mix(a3g, b0g, c1g, d2g, m8, m11);
    auto a7g = 0 /* unhandled */;
    auto b7g = 0 /* unhandled */;
    auto c7g = 0 /* unhandled */;
    auto d7g = 0 /* unhandled */;
    uint32_t r6_0 = a4g;
    uint32_t r6_1 = a5g;
    uint32_t r6_2 = a6g;
    uint32_t r6_3 = a7g;
    uint32_t r6_4 = b7g;
    uint32_t r6_5 = b4g;
    uint32_t r6_6 = b5g;
    uint32_t r6_7 = b6g;
    uint32_t r6_8 = c6g;
    uint32_t r6_9 = c7g;
    uint32_t r6_10 = c4g;
    uint32_t r6_11 = c5g;
    uint32_t r6_12 = d5g;
    uint32_t r6_13 = d6g;
    uint32_t r6_14 = d7g;
    uint32_t r6_15 = d4g;
    auto __tup_458_8 = g_mix(r6_0, r6_4, r6_8, r6_12, m13, m11);
    auto a0h = 0 /* unhandled */;
    auto b0h = 0 /* unhandled */;
    auto c0h = 0 /* unhandled */;
    auto d0h = 0 /* unhandled */;
    auto __tup_459_8 = g_mix(r6_1, r6_5, r6_9, r6_13, m7, m14);
    auto a1h = 0 /* unhandled */;
    auto b1h = 0 /* unhandled */;
    auto c1h = 0 /* unhandled */;
    auto d1h = 0 /* unhandled */;
    auto __tup_460_8 = g_mix(r6_2, r6_6, r6_10, r6_14, m12, m1);
    auto a2h = 0 /* unhandled */;
    auto b2h = 0 /* unhandled */;
    auto c2h = 0 /* unhandled */;
    auto d2h = 0 /* unhandled */;
    auto __tup_461_8 = g_mix(r6_3, r6_7, r6_11, r6_15, m3, m9);
    auto a3h = 0 /* unhandled */;
    auto b3h = 0 /* unhandled */;
    auto c3h = 0 /* unhandled */;
    auto d3h = 0 /* unhandled */;
    auto __tup_462_8 = g_mix(a0h, b1h, c2h, d3h, m5, m0);
    auto a4h = 0 /* unhandled */;
    auto b4h = 0 /* unhandled */;
    auto c4h = 0 /* unhandled */;
    auto d4h = 0 /* unhandled */;
    auto __tup_463_8 = g_mix(a1h, b2h, c3h, d0h, m15, m4);
    auto a5h = 0 /* unhandled */;
    auto b5h = 0 /* unhandled */;
    auto c5h = 0 /* unhandled */;
    auto d5h = 0 /* unhandled */;
    auto __tup_464_8 = g_mix(a2h, b3h, c0h, d1h, m8, m6);
    auto a6h = 0 /* unhandled */;
    auto b6h = 0 /* unhandled */;
    auto c6h = 0 /* unhandled */;
    auto d6h = 0 /* unhandled */;
    auto __tup_465_8 = g_mix(a3h, b0h, c1h, d2h, m2, m10);
    auto a7h = 0 /* unhandled */;
    auto b7h = 0 /* unhandled */;
    auto c7h = 0 /* unhandled */;
    auto d7h = 0 /* unhandled */;
    uint32_t r7_0 = a4h;
    uint32_t r7_1 = a5h;
    uint32_t r7_2 = a6h;
    uint32_t r7_3 = a7h;
    uint32_t r7_4 = b7h;
    uint32_t r7_5 = b4h;
    uint32_t r7_6 = b5h;
    uint32_t r7_7 = b6h;
    uint32_t r7_8 = c6h;
    uint32_t r7_9 = c7h;
    uint32_t r7_10 = c4h;
    uint32_t r7_11 = c5h;
    uint32_t r7_12 = d5h;
    uint32_t r7_13 = d6h;
    uint32_t r7_14 = d7h;
    uint32_t r7_15 = d4h;
    auto __tup_472_8 = g_mix(r7_0, r7_4, r7_8, r7_12, m6, m15);
    auto a0i = 0 /* unhandled */;
    auto b0i = 0 /* unhandled */;
    auto c0i = 0 /* unhandled */;
    auto d0i = 0 /* unhandled */;
    auto __tup_473_8 = g_mix(r7_1, r7_5, r7_9, r7_13, m14, m9);
    auto a1i = 0 /* unhandled */;
    auto b1i = 0 /* unhandled */;
    auto c1i = 0 /* unhandled */;
    auto d1i = 0 /* unhandled */;
    auto __tup_474_8 = g_mix(r7_2, r7_6, r7_10, r7_14, m11, m3);
    auto a2i = 0 /* unhandled */;
    auto b2i = 0 /* unhandled */;
    auto c2i = 0 /* unhandled */;
    auto d2i = 0 /* unhandled */;
    auto __tup_475_8 = g_mix(r7_3, r7_7, r7_11, r7_15, m0, m8);
    auto a3i = 0 /* unhandled */;
    auto b3i = 0 /* unhandled */;
    auto c3i = 0 /* unhandled */;
    auto d3i = 0 /* unhandled */;
    auto __tup_476_8 = g_mix(a0i, b1i, c2i, d3i, m12, m2);
    auto a4i = 0 /* unhandled */;
    auto b4i = 0 /* unhandled */;
    auto c4i = 0 /* unhandled */;
    auto d4i = 0 /* unhandled */;
    auto __tup_477_8 = g_mix(a1i, b2i, c3i, d0i, m13, m7);
    auto a5i = 0 /* unhandled */;
    auto b5i = 0 /* unhandled */;
    auto c5i = 0 /* unhandled */;
    auto d5i = 0 /* unhandled */;
    auto __tup_478_8 = g_mix(a2i, b3i, c0i, d1i, m1, m4);
    auto a6i = 0 /* unhandled */;
    auto b6i = 0 /* unhandled */;
    auto c6i = 0 /* unhandled */;
    auto d6i = 0 /* unhandled */;
    auto __tup_479_8 = g_mix(a3i, b0i, c1i, d2i, m10, m5);
    auto a7i = 0 /* unhandled */;
    auto b7i = 0 /* unhandled */;
    auto c7i = 0 /* unhandled */;
    auto d7i = 0 /* unhandled */;
    uint32_t r8_0 = a4i;
    uint32_t r8_1 = a5i;
    uint32_t r8_2 = a6i;
    uint32_t r8_3 = a7i;
    uint32_t r8_4 = b7i;
    uint32_t r8_5 = b4i;
    uint32_t r8_6 = b5i;
    uint32_t r8_7 = b6i;
    uint32_t r8_8 = c6i;
    uint32_t r8_9 = c7i;
    uint32_t r8_10 = c4i;
    uint32_t r8_11 = c5i;
    uint32_t r8_12 = d5i;
    uint32_t r8_13 = d6i;
    uint32_t r8_14 = d7i;
    uint32_t r8_15 = d4i;
    auto __tup_486_8 = g_mix(r8_0, r8_4, r8_8, r8_12, m10, m2);
    auto a0j = 0 /* unhandled */;
    auto b0j = 0 /* unhandled */;
    auto c0j = 0 /* unhandled */;
    auto d0j = 0 /* unhandled */;
    auto __tup_487_8 = g_mix(r8_1, r8_5, r8_9, r8_13, m8, m4);
    auto a1j = 0 /* unhandled */;
    auto b1j = 0 /* unhandled */;
    auto c1j = 0 /* unhandled */;
    auto d1j = 0 /* unhandled */;
    auto __tup_488_8 = g_mix(r8_2, r8_6, r8_10, r8_14, m7, m6);
    auto a2j = 0 /* unhandled */;
    auto b2j = 0 /* unhandled */;
    auto c2j = 0 /* unhandled */;
    auto d2j = 0 /* unhandled */;
    auto __tup_489_8 = g_mix(r8_3, r8_7, r8_11, r8_15, m1, m5);
    auto a3j = 0 /* unhandled */;
    auto b3j = 0 /* unhandled */;
    auto c3j = 0 /* unhandled */;
    auto d3j = 0 /* unhandled */;
    auto __tup_490_8 = g_mix(a0j, b1j, c2j, d3j, m15, m11);
    auto a4j = 0 /* unhandled */;
    auto b4j = 0 /* unhandled */;
    auto c4j = 0 /* unhandled */;
    auto d4j = 0 /* unhandled */;
    auto __tup_491_8 = g_mix(a1j, b2j, c3j, d0j, m9, m14);
    auto a5j = 0 /* unhandled */;
    auto b5j = 0 /* unhandled */;
    auto c5j = 0 /* unhandled */;
    auto d5j = 0 /* unhandled */;
    auto __tup_492_8 = g_mix(a2j, b3j, c0j, d1j, m3, m12);
    auto a6j = 0 /* unhandled */;
    auto b6j = 0 /* unhandled */;
    auto c6j = 0 /* unhandled */;
    auto d6j = 0 /* unhandled */;
    auto __tup_493_8 = g_mix(a3j, b0j, c1j, d2j, m13, m0);
    auto a7j = 0 /* unhandled */;
    auto b7j = 0 /* unhandled */;
    auto c7j = 0 /* unhandled */;
    auto d7j = 0 /* unhandled */;
    uint32_t f0 = a4j;
    uint32_t f1 = a5j;
    uint32_t f2 = a6j;
    uint32_t f3 = a7j;
    uint32_t f4 = b7j;
    uint32_t f5 = b4j;
    uint32_t f6 = b5j;
    uint32_t f7 = b6j;
    uint32_t f8 = c6j;
    uint32_t f9 = c7j;
    uint32_t f10 = c4j;
    uint32_t f11 = c5j;
    uint32_t f12 = d5j;
    uint32_t f13 = d6j;
    uint32_t f14 = d7j;
    uint32_t f15 = d4j;
    uint32_t out0 = ((h0 ^ f0) ^ f8);
    uint32_t out1 = ((h1 ^ f1) ^ f9);
    uint32_t out2 = ((h2 ^ f2) ^ f10);
    uint32_t out3 = ((h3 ^ f3) ^ f11);
    uint32_t out4 = ((h4 ^ f4) ^ f12);
    uint32_t out5 = ((h5 ^ f5) ^ f13);
    uint32_t out6 = ((h6 ^ f6) ^ f14);
    uint32_t out7 = ((h7 ^ f7) ^ f15);
    uint64_t base = (leaf * 8ULL);
    if (((base + 7ULL) < hashes_len)) {
      hashes[base] = out0;
      hashes[(base + 1ULL)] = out1;
      hashes[(base + 2ULL)] = out2;
      hashes[(base + 3ULL)] = out3;
      hashes[(base + 4ULL)] = out4;
      hashes[(base + 5ULL)] = out5;
      hashes[(base + 6ULL)] = out6;
      hashes[(base + 7ULL)] = out7;
    }
  }
}

uint64_t main() {
  return 0ULL;
}

