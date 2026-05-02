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

__device__ uint32_t bit_reverse_u32(uint32_t v, uint32_t log_n) {
  uint32_t r = 0U;
  uint32_t x = v;
  uint32_t i = 0U;
  while ((i < log_n)) {
    r = ((r << 1U) | (x & 1U));
    x = (x >> 1U);
    i = (i + 1U);
  }
  return r;
}

__global__ void bit_reverse_qm31(uint32_t* __restrict__ in_buf, uint64_t in_buf_len, uint32_t* __restrict__ out_buf, uint64_t out_buf_len, uint64_t n, uint32_t log_n) {
  uint64_t i = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((i < n)) {
    uint32_t j = bit_reverse_u32(((uint32_t)i), log_n);
    uint64_t src_off = (i * 4ULL);
    uint64_t dst_off = (((uint64_t)j) * 4ULL);
    if (((src_off + 3ULL) < in_buf_len)) {
      if (((dst_off + 3ULL) < out_buf_len)) {
        out_buf[dst_off] = in_buf[src_off];
        out_buf[(dst_off + 1ULL)] = in_buf[(src_off + 1ULL)];
        out_buf[(dst_off + 2ULL)] = in_buf[(src_off + 2ULL)];
        out_buf[(dst_off + 3ULL)] = in_buf[(src_off + 3ULL)];
      }
    }
  }
}

uint64_t main() {
  return 0ULL;
}

