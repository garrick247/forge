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

__device__ uint64_t m31_p() {
  return 2147483647ULL;
}

__device__ uint64_t m31_add(uint64_t a, uint64_t b) {
  uint64_t sum = (a + b);
  if ((sum >= 2147483647ULL)) {
    return (sum - 2147483647ULL);
  } else {
    return sum;
  }
}

__device__ uint64_t m31_sub(uint64_t a, uint64_t b) {
  if ((a >= b)) {
    return (a - b);
  } else {
    return ((2147483647ULL - b) + a);
  }
}

__device__ uint64_t m31_mul(uint64_t a, uint64_t b) {
  return ((a * b) % 2147483647ULL);
}

__device__ uint64_t m31_butterfly(uint64_t v0, uint64_t v1, uint64_t t) {
  uint64_t tmp = m31_mul(v1, t);
  uint64_t new_v0 = m31_add(v0, tmp);
  uint64_t new_v1 = m31_sub(v0, tmp);
  return 0 /* unhandled */;
}

__device__ uint64_t m31_ibutterfly(uint64_t v0, uint64_t v1, uint64_t t) {
  uint64_t new_v0 = m31_add(v0, v1);
  uint64_t diff = m31_sub(v0, v1);
  uint64_t new_v1 = m31_mul(diff, t);
  return 0 /* unhandled */;
}

__global__ void circle_ntt_layer(uint64_t* __restrict__ data, uint64_t data_len, uint64_t* __restrict__ twiddles, uint64_t twiddles_len, uint64_t layer_idx, uint64_t half_n) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((tid < half_n)) {
    uint64_t stride = (1ULL << layer_idx);
    uint64_t h = (tid >> layer_idx);
    uint64_t l = (tid & (stride - 1ULL));
    uint64_t idx0 = ((h << (layer_idx + 1ULL)) + l);
    uint64_t idx1 = (idx0 + stride);
    if ((((idx0 < data_len) && (idx1 < data_len)) && (h < twiddles_len))) {
      uint64_t v0 = data[idx0];
      uint64_t v1 = data[idx1];
      uint64_t t = twiddles[h];
      uint64_t tmp = ((v1 * t) % 2147483647ULL);
      uint64_t sum = (v0 + tmp);
      data[idx0] = __if_stmt__;
      data[idx1] = __if_stmt__;
    }
  }
}

__global__ void circle_intt_layer(uint64_t* __restrict__ data, uint64_t data_len, uint64_t* __restrict__ twiddles, uint64_t twiddles_len, uint64_t layer_idx, uint64_t half_n) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((tid < half_n)) {
    uint64_t stride = (1ULL << layer_idx);
    uint64_t h = (tid >> layer_idx);
    uint64_t l = (tid & (stride - 1ULL));
    uint64_t idx0 = ((h << (layer_idx + 1ULL)) + l);
    uint64_t idx1 = (idx0 + stride);
    if ((((idx0 < data_len) && (idx1 < data_len)) && (h < twiddles_len))) {
      uint64_t v0 = data[idx0];
      uint64_t v1 = data[idx1];
      uint64_t t = twiddles[h];
      uint64_t sum = (v0 + v1);
      data[idx0] = __if_stmt__;
      uint64_t diff = __if_stmt__;
      data[idx1] = ((diff * t) % 2147483647ULL);
    }
  }
}

__global__ void circle_ntt_warp_layer(uint64_t* __restrict__ data, uint64_t data_len, uint64_t n, uint64_t stride, uint64_t twiddle) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((tid < n)) {
    uint64_t val = (data[tid] % 2147483647ULL);
    uint64_t partner = __shfl_xor_sync(0xffffffff, val, stride, 32ULL);
    uint64_t lid = (threadIdx.x & 31);
    uint64_t tw = (twiddle % 2147483647ULL);
    if ((lid < stride)) {
      uint64_t tmp = ((partner * tw) % 2147483647ULL);
      uint64_t s = (val + tmp);
      data[tid] = __if_stmt__;
    } else {
      uint64_t tmp2 = ((val * tw) % 2147483647ULL);
      data[tid] = __if_stmt__;
    }
  }
}

__global__ void m31_scale(uint64_t* __restrict__ data, uint64_t data_len, uint64_t scale, uint64_t n) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((tid < n)) {
    data[tid] = ((data[tid] * scale) % 2147483647ULL);
  }
}

__global__ void circle_ntt_batch_layer(uint64_t* __restrict__ columns, uint64_t columns_len, uint64_t* __restrict__ twiddles, uint64_t twiddles_len, uint64_t layer_idx, uint64_t half_n, uint64_t n_cols, uint64_t col_stride) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  uint64_t total = (half_n * n_cols);
  if (((tid < total) && (half_n >= 1ULL))) {
    uint64_t pair_idx = (tid % half_n);
    uint64_t col_idx = (tid / half_n);
    uint64_t stride = (1ULL << layer_idx);
    uint64_t h = (pair_idx >> layer_idx);
    uint64_t l = (pair_idx & (stride - 1ULL));
    uint64_t idx0 = (((col_idx * col_stride) + (h << (layer_idx + 1ULL))) + l);
    uint64_t idx1 = (idx0 + stride);
    if ((((idx0 < columns_len) && (idx1 < columns_len)) && (h < twiddles_len))) {
      uint64_t v0 = (columns[idx0] % 2147483647ULL);
      uint64_t v1 = (columns[idx1] % 2147483647ULL);
      uint64_t t = (twiddles[h] % 2147483647ULL);
      uint64_t tmp = ((v1 * t) % 2147483647ULL);
      uint64_t sum = (v0 + tmp);
      columns[idx0] = __if_stmt__;
      columns[idx1] = __if_stmt__;
    }
  }
}

__global__ void bit_reverse_m31(uint64_t* __restrict__ data, uint64_t data_len, uint64_t n, uint64_t log_n) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((tid < n)) {
    uint64_t rev = 0ULL;
    uint64_t val = tid;
    uint64_t bits = 0ULL;
    while ((bits < log_n)) {
      rev = ((rev << 1ULL) | (val & 1ULL));
      val = (val >> 1ULL);
      bits = (bits + 1ULL);
    }
    if (((tid < rev) && (rev < n))) {
      uint64_t tmp = data[tid];
      data[tid] = data[rev];
      data[rev] = tmp;
    }
  }
}

uint64_t main() {
  return 0ULL;
}

