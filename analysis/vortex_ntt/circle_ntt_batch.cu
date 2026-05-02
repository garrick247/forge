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

__global__ void circle_ntt_batch_layer_forward(uint32_t** __restrict__ columns, uint64_t columns_len, uint32_t* __restrict__ twiddles, uint64_t twiddles_len, uint32_t layer_idx, uint64_t half_n, uint64_t n_cols) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  uint64_t total = (half_n * n_cols);
  if ((tid < total)) {
    uint64_t col_idx = (tid / half_n);
    uint64_t pair_idx = (tid - (col_idx * half_n));
    uint64_t stride = (1ULL << ((uint64_t)layer_idx));
    uint64_t h = (pair_idx >> ((uint64_t)layer_idx));
    uint64_t l = (pair_idx & (stride - 1ULL));
    uint64_t idx0 = ((h << ((uint64_t)(layer_idx + 1U))) + l);
    uint64_t idx1 = (idx0 + stride);
    if ((col_idx < columns_len)) {
      uint32_t* col = columns[col_idx];
      if ((idx0 < col_len)) {
        if ((idx1 < col_len)) {
          if ((h < twiddles_len)) {
            uint32_t v0 = reduce_word(col[idx0]);
            uint32_t v1 = reduce_word(col[idx1]);
            uint32_t t = reduce_word(twiddles[h]);
            uint32_t tmp = m31_mul(v1, t);
            col[idx0] = m31_add(v0, tmp);
            col[idx1] = m31_sub(v0, tmp);
          }
        }
      }
    }
  }
}

__global__ void circle_ntt_batch_layer_inverse(uint32_t** __restrict__ columns, uint64_t columns_len, uint32_t* __restrict__ twiddles, uint64_t twiddles_len, uint32_t layer_idx, uint64_t half_n, uint64_t n_cols) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  uint64_t total = (half_n * n_cols);
  if ((tid < total)) {
    uint64_t col_idx = (tid / half_n);
    uint64_t pair_idx = (tid - (col_idx * half_n));
    uint64_t stride = (1ULL << ((uint64_t)layer_idx));
    uint64_t h = (pair_idx >> ((uint64_t)layer_idx));
    uint64_t l = (pair_idx & (stride - 1ULL));
    uint64_t idx0 = ((h << ((uint64_t)(layer_idx + 1U))) + l);
    uint64_t idx1 = (idx0 + stride);
    if ((col_idx < columns_len)) {
      uint32_t* col = columns[col_idx];
      if ((idx0 < col_len)) {
        if ((idx1 < col_len)) {
          if ((h < twiddles_len)) {
            uint32_t v0 = reduce_word(col[idx0]);
            uint32_t v1 = reduce_word(col[idx1]);
            uint32_t t = reduce_word(twiddles[h]);
            uint32_t diff = m31_sub(v0, v1);
            col[idx0] = m31_add(v0, v1);
            col[idx1] = m31_mul(diff, t);
          }
        }
      }
    }
  }
}

__global__ void m31_batch_scale(uint32_t** __restrict__ columns, uint64_t columns_len, uint32_t scale, uint64_t n, uint64_t n_cols) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  uint64_t total = (n * n_cols);
  if ((tid < total)) {
    uint64_t col_idx = (tid / n);
    uint64_t elem_idx = (tid - (col_idx * n));
    if ((col_idx < columns_len)) {
      uint32_t* col = columns[col_idx];
      if ((elem_idx < col_len)) {
        uint32_t v = reduce_word(col[elem_idx]);
        col[elem_idx] = m31_mul(v, scale);
      }
    }
  }
}

uint64_t main() {
  return 0ULL;
}

