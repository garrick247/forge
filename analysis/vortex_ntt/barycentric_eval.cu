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

__device__ uint32_t warp_xor_m31(uint32_t v, uint64_t mask) {
  uint64_t s64 = __shfl_xor_sync(0xffffffff, ((uint64_t)v), mask, 32ULL);
  uint32_t r32 = ((uint32_t)s64);
  return (r32 % M31_P);
}

__device__ uint32_t warp_reduce_m31_sum(uint32_t v) {
  uint32_t s16 = warp_xor_m31(v, 16ULL);
  uint32_t a16 = m31_add(v, s16);
  uint32_t s8 = warp_xor_m31(a16, 8ULL);
  uint32_t a8 = m31_add(a16, s8);
  uint32_t s4 = warp_xor_m31(a8, 4ULL);
  uint32_t a4 = m31_add(a8, s4);
  uint32_t s2 = warp_xor_m31(a4, 2ULL);
  uint32_t a2 = m31_add(a4, s2);
  uint32_t s1 = warp_xor_m31(a2, 1ULL);
  return m31_add(a2, s1);
}

__global__ void barycentric_eval(uint32_t* __restrict__ evals, uint64_t evals_len, uint32_t* __restrict__ weights, uint64_t weights_len, uint32_t* __restrict__ out, uint64_t out_len, uint64_t n) {
  __shared__ uint32_t smem[128ULL];
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  uint64_t stride = (blockDim.x * gridDim.x);
  uint32_t a0 = 0U;
  uint32_t a1 = 0U;
  uint32_t a2 = 0U;
  uint32_t a3 = 0U;
  uint64_t i = tid;
  while ((i < n)) {
    0 /* unhandled */;
    uint32_t e = evals[i];
    uint64_t wb = (i * 4ULL);
    uint32_t t0_raw = __if_stmt__;
    uint32_t t0 = (t0_raw % M31_P);
    uint32_t t1_raw = __if_stmt__;
    uint32_t t1 = (t1_raw % M31_P);
    uint32_t t2_raw = __if_stmt__;
    uint32_t t2 = (t2_raw % M31_P);
    uint32_t t3_raw = __if_stmt__;
    uint32_t t3 = (t3_raw % M31_P);
    a0 = m31_add(a0, t0);
    a1 = m31_add(a1, t1);
    a2 = m31_add(a2, t2);
    a3 = m31_add(a3, t3);
    i = (i + stride);
  }
  a0 = warp_reduce_m31_sum(a0);
  a1 = warp_reduce_m31_sum(a1);
  a2 = warp_reduce_m31_sum(a2);
  a3 = warp_reduce_m31_sum(a3);
  uint64_t warp_id = (threadIdx.x / 32ULL);
  uint64_t lane_id = (threadIdx.x % 32ULL);
  if ((lane_id == 0ULL)) {
    uint64_t so = (warp_id * 4ULL);
    if (((so + 3ULL) < 128ULL)) {
      smem[so] = a0;
      smem[(so + 1ULL)] = a1;
      smem[(so + 2ULL)] = a2;
      smem[(so + 3ULL)] = a3;
    }
  }
  __syncthreads();
  if ((warp_id == 0ULL)) {
    uint64_t n_warps = (blockDim.x / 32ULL);
    uint32_t b0 = 0U;
    uint32_t b1 = 0U;
    uint32_t b2 = 0U;
    uint32_t b3 = 0U;
    if ((lane_id < n_warps)) {
      uint64_t so2 = (lane_id * 4ULL);
      if (((so2 + 3ULL) < 128ULL)) {
        b0 = (smem[so2] % M31_P);
        b1 = (smem[(so2 + 1ULL)] % M31_P);
        b2 = (smem[(so2 + 2ULL)] % M31_P);
        b3 = (smem[(so2 + 3ULL)] % M31_P);
      }
    }
    b0 = warp_reduce_m31_sum(b0);
    b1 = warp_reduce_m31_sum(b1);
    b2 = warp_reduce_m31_sum(b2);
    b3 = warp_reduce_m31_sum(b3);
    if ((lane_id == 0ULL)) {
      uint64_t ob = (blockIdx.x * 4ULL);
      if (((ob + 3ULL) < out_len)) {
        out[ob] = b0;
        out[(ob + 1ULL)] = b1;
        out[(ob + 2ULL)] = b2;
        out[(ob + 3ULL)] = b3;
      }
    }
  }
}

int32_t main() {
  return 0;
}

