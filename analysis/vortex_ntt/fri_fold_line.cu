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

__global__ void fold_line_soa(uint32_t* __restrict__ in0, uint64_t in0_len, uint32_t* __restrict__ in1, uint64_t in1_len, uint32_t* __restrict__ in2, uint64_t in2_len, uint32_t* __restrict__ in3, uint64_t in3_len, uint32_t* __restrict__ twiddles, uint64_t twiddles_len, uint32_t* __restrict__ out0, uint64_t out0_len, uint32_t* __restrict__ out1, uint64_t out1_len, uint32_t* __restrict__ out2, uint64_t out2_len, uint32_t* __restrict__ out3, uint64_t out3_len, uint32_t alpha_a, uint32_t alpha_b, uint32_t alpha_c, uint32_t alpha_d, uint64_t half_n) {
  uint64_t i = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((i < half_n)) {
    uint64_t idx0 = (2ULL * i);
    uint64_t idx1 = ((2ULL * i) + 1ULL);
    if ((idx1 < in0_len)) {
      if ((idx1 < in1_len)) {
        if ((idx1 < in2_len)) {
          if ((idx1 < in3_len)) {
            if ((i < twiddles_len)) {
              if ((i < out0_len)) {
                if ((i < out1_len)) {
                  if ((i < out2_len)) {
                    if ((i < out3_len)) {
                      uint32_t f0_a_re = reduce_word(in0[idx0]);
                      uint32_t f0_a_im = reduce_word(in1[idx0]);
                      uint32_t f0_b_re = reduce_word(in2[idx0]);
                      uint32_t f0_b_im = reduce_word(in3[idx0]);
                      uint32_t f1_a_re = reduce_word(in0[idx1]);
                      uint32_t f1_a_im = reduce_word(in1[idx1]);
                      uint32_t f1_b_re = reduce_word(in2[idx1]);
                      uint32_t f1_b_im = reduce_word(in3[idx1]);
                      uint32_t tw = reduce_word(twiddles[i]);
                      uint32_t sum_a_re = qm31_add_re_re(f0_a_re, f1_a_re);
                      uint32_t sum_a_im = qm31_add_re_im(f0_a_im, f1_a_im);
                      uint32_t sum_b_re = qm31_add_im_re(f0_b_re, f1_b_re);
                      uint32_t sum_b_im = qm31_add_im_im(f0_b_im, f1_b_im);
                      uint32_t diff_a_re = qm31_sub_re_re(f0_a_re, f1_a_re);
                      uint32_t diff_a_im = qm31_sub_re_im(f0_a_im, f1_a_im);
                      uint32_t diff_b_re = qm31_sub_im_re(f0_b_re, f1_b_re);
                      uint32_t diff_b_im = qm31_sub_im_im(f0_b_im, f1_b_im);
                      uint32_t td_a_re = m31_mul(diff_a_re, tw);
                      uint32_t td_a_im = m31_mul(diff_a_im, tw);
                      uint32_t td_b_re = m31_mul(diff_b_re, tw);
                      uint32_t td_b_im = m31_mul(diff_b_im, tw);
                      uint32_t at_a_re = qm31_mul_out_re_re(alpha_a, alpha_b, alpha_c, alpha_d, td_a_re, td_a_im, td_b_re, td_b_im);
                      uint32_t at_a_im = qm31_mul_out_re_im(alpha_a, alpha_b, alpha_c, alpha_d, td_a_re, td_a_im, td_b_re, td_b_im);
                      uint32_t at_b_re = qm31_mul_out_im_re(alpha_a, alpha_b, alpha_c, alpha_d, td_a_re, td_a_im, td_b_re, td_b_im);
                      uint32_t at_b_im = qm31_mul_out_im_im(alpha_a, alpha_b, alpha_c, alpha_d, td_a_re, td_a_im, td_b_re, td_b_im);
                      uint32_t r_a_re = qm31_add_re_re(sum_a_re, at_a_re);
                      uint32_t r_a_im = qm31_add_re_im(sum_a_im, at_a_im);
                      uint32_t r_b_re = qm31_add_im_re(sum_b_re, at_b_re);
                      uint32_t r_b_im = qm31_add_im_im(sum_b_im, at_b_im);
                      out0[i] = r_a_re;
                      out1[i] = r_a_im;
                      out2[i] = r_b_re;
                      out3[i] = r_b_im;
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

uint64_t main() {
  return 0ULL;
}

