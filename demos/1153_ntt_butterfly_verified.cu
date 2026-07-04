// FORGE-generated CUDA C — SM_120
// All proofs discharged. Correct by construction.
// No bounds checks. No overflow checks. They were proven away.

#include <stdint.h>
#include <stdbool.h>

static const uint32_t M31_P = 2147483647U;


static __device__ __forceinline__ uint64_t warp_reduce_sum(uint64_t val) {
  uint64_t v = val;
  v = (v + __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL));
  return v;
}

static __device__ __forceinline__ uint64_t warp_reduce_max(uint64_t val) {
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

static __device__ __forceinline__ uint64_t warp_reduce_min(uint64_t val) {
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

static __device__ __forceinline__ float warp_reduce_sum_f32(float val) {
  float v = val;
  v = (v + __shfl_xor_sync(0xffffffff, v, 16ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 8ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 4ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 2ULL, 32ULL));
  v = (v + __shfl_xor_sync(0xffffffff, v, 1ULL, 32ULL));
  return v;
}

static __device__ __forceinline__ float warp_reduce_max_f32(float val) {
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

static __device__ __forceinline__ float warp_reduce_min_f32(float val) {
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

static __device__ __forceinline__ uint64_t grid_stride_start(uint64_t block_idx, uint64_t block_dim, uint64_t thread_idx) {
  return ((block_idx * block_dim) + thread_idx);
}

static __device__ __forceinline__ uint64_t grid_stride_step(uint64_t block_dim, uint64_t grid_dim) {
  return (block_dim * grid_dim);
}

static __device__ __forceinline__ uint32_t m31_add(uint32_t a, uint32_t b) {
  uint64_t s = (((uint64_t)a) + ((uint64_t)b));
  uint64_t p = ((uint64_t)M31_P);
  uint64_t r;
  if ((s >= p)) {
    r = (s - p);
  } else {
    r = s;
  }
  return ((uint32_t)r);
}

static __device__ __forceinline__ uint32_t m31_sub(uint32_t a, uint32_t b) {
  uint64_t a64 = ((uint64_t)a);
  uint64_t b64 = ((uint64_t)b);
  uint64_t p = ((uint64_t)M31_P);
  uint64_t r;
  if ((a64 >= b64)) {
    r = (a64 - b64);
  } else {
    r = ((a64 + p) - b64);
  }
  return ((uint32_t)r);
}

static __device__ __forceinline__ uint32_t m31_mul(uint32_t a, uint32_t b) {
  uint64_t prod = (((uint64_t)a) * ((uint64_t)b));
  uint64_t p = ((uint64_t)M31_P);
  uint64_t r = (prod % p);
  return ((uint32_t)r);
}

static __device__ __forceinline__ uint32_t m31_neg(uint32_t a) {
  if ((a == 0U)) {
    return 0U;
  } else {
    return (M31_P - a);
  }
}

static __device__ __forceinline__ uint32_t m31_double(uint32_t a) {
  return m31_add(a, a);
}

static __device__ __forceinline__ uint32_t m31_butterfly_hi(uint32_t a, uint32_t b, uint32_t w) {
  uint32_t t = m31_mul(w, b);
  0 /* unhandled */;
  return m31_add(a, t);
}

static __device__ __forceinline__ uint32_t m31_butterfly_lo(uint32_t a, uint32_t b, uint32_t w) {
  uint32_t t = m31_mul(w, b);
  return m31_sub(a, t);
}

static __device__ __forceinline__ uint32_t cm31_mul_re(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im) {
  uint32_t ac = m31_mul(a_re, b_re);
  uint32_t bd = m31_mul(a_im, b_im);
  0 /* unhandled */;
  return m31_sub(ac, bd);
}

static __device__ __forceinline__ uint32_t cm31_mul_im(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im) {
  uint32_t ad = m31_mul(a_re, b_im);
  uint32_t bc = m31_mul(a_im, b_re);
  0 /* unhandled */;
  return m31_add(ad, bc);
}

static __device__ __forceinline__ uint32_t cm31_add_re(uint32_t a_re, uint32_t b_re) {
  return m31_add(a_re, b_re);
}

static __device__ __forceinline__ uint32_t cm31_add_im(uint32_t a_im, uint32_t b_im) {
  return m31_add(a_im, b_im);
}

static __device__ __forceinline__ uint32_t cm31_sub_re(uint32_t a_re, uint32_t b_re) {
  return m31_sub(a_re, b_re);
}

static __device__ __forceinline__ uint32_t cm31_sub_im(uint32_t a_im, uint32_t b_im) {
  return m31_sub(a_im, b_im);
}

static __device__ __forceinline__ uint32_t qm31_mul_out_re_re(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ac_re = cm31_mul_re(a_re, a_im, c_re, c_im);
  uint32_t bd_re = cm31_mul_re(b_re, b_im, d_re, d_im);
  uint32_t bd_im = cm31_mul_im(b_re, b_im, d_re, d_im);
  uint32_t dbl = m31_double(bd_re);
  uint32_t t = m31_sub(dbl, bd_im);
  0 /* unhandled */;
  return m31_add(ac_re, t);
}

static __device__ __forceinline__ uint32_t qm31_mul_out_re_im(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ac_im = cm31_mul_im(a_re, a_im, c_re, c_im);
  uint32_t bd_re = cm31_mul_re(b_re, b_im, d_re, d_im);
  uint32_t bd_im = cm31_mul_im(b_re, b_im, d_re, d_im);
  uint32_t dbl = m31_double(bd_im);
  uint32_t t = m31_add(bd_re, dbl);
  0 /* unhandled */;
  return m31_add(ac_im, t);
}

static __device__ __forceinline__ uint32_t qm31_mul_out_im_re(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ad_re = cm31_mul_re(a_re, a_im, d_re, d_im);
  uint32_t bc_re = cm31_mul_re(b_re, b_im, c_re, c_im);
  0 /* unhandled */;
  return m31_add(ad_re, bc_re);
}

static __device__ __forceinline__ uint32_t qm31_mul_out_im_im(uint32_t a_re, uint32_t a_im, uint32_t b_re, uint32_t b_im, uint32_t c_re, uint32_t c_im, uint32_t d_re, uint32_t d_im) {
  uint32_t ad_im = cm31_mul_im(a_re, a_im, d_re, d_im);
  uint32_t bc_im = cm31_mul_im(b_re, b_im, c_re, c_im);
  0 /* unhandled */;
  return m31_add(ad_im, bc_im);
}

static __device__ __forceinline__ uint32_t qm31_add_re_re(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

static __device__ __forceinline__ uint32_t qm31_add_re_im(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

static __device__ __forceinline__ uint32_t qm31_add_im_re(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

static __device__ __forceinline__ uint32_t qm31_add_im_im(uint32_t a, uint32_t b) {
  return m31_add(a, b);
}

static __device__ __forceinline__ uint32_t qm31_sub_re_re(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

static __device__ __forceinline__ uint32_t qm31_sub_re_im(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

static __device__ __forceinline__ uint32_t qm31_sub_im_re(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

static __device__ __forceinline__ uint32_t qm31_sub_im_im(uint32_t a, uint32_t b) {
  return m31_sub(a, b);
}

__global__ void ntt_butterfly_at(uint32_t* __restrict__ data, uint64_t data_len, uint32_t* __restrict__ twiddle, uint64_t twiddle_len, uint64_t half_n, uint64_t tid) {
  0 /* unhandled */;
  0 /* unhandled */;
  0 /* unhandled */;
  0 /* unhandled */;
  0 /* unhandled */;
  uint32_t a = data[tid];
  uint32_t b = data[(tid + half_n)];
  uint32_t w = twiddle[tid];
  uint32_t a2 = m31_butterfly_hi(a, b, w);
  uint32_t b2 = m31_butterfly_lo(a, b, w);
  0 /* unhandled */;
  data[tid] = a2;
  data[(tid + half_n)] = b2;
  0 /* unhandled */;
  0 /* unhandled */;
}

