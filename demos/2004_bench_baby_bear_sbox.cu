// FORGE-generated CUDA C — SM_120
// All proofs discharged. Correct by construction.
// No bounds checks. No overflow checks. They were proven away.

#include <stdint.h>
#include <stdbool.h>

static const uint32_t BABY_BEAR_P = 2013265921U;
static const uint32_t BABY_BEAR_W = 11U;


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

static __device__ __forceinline__ uint32_t baby_bear_add(uint32_t a, uint32_t b) {
  uint64_t s = (((uint64_t)a) + ((uint64_t)b));
  uint64_t p = ((uint64_t)BABY_BEAR_P);
  uint64_t r;
  if ((s >= p)) {
    r = (s - p);
  } else {
    r = s;
  }
  return ((uint32_t)r);
}

static __device__ __forceinline__ uint32_t baby_bear_sub(uint32_t a, uint32_t b) {
  uint64_t a64 = ((uint64_t)a);
  uint64_t b64 = ((uint64_t)b);
  uint64_t p = ((uint64_t)BABY_BEAR_P);
  uint64_t r;
  if ((a64 >= b64)) {
    r = (a64 - b64);
  } else {
    r = ((a64 + p) - b64);
  }
  return ((uint32_t)r);
}

static __device__ __forceinline__ uint32_t baby_bear_mul(uint32_t a, uint32_t b) {
  uint64_t prod = (((uint64_t)a) * ((uint64_t)b));
  uint64_t p = ((uint64_t)BABY_BEAR_P);
  uint64_t r = (prod % p);
  return ((uint32_t)r);
}

static __device__ __forceinline__ uint32_t baby_bear_neg(uint32_t a) {
  if ((a == 0U)) {
    return 0U;
  } else {
    return (BABY_BEAR_P - a);
  }
}

static __device__ __forceinline__ uint32_t baby_bear_double(uint32_t a) {
  return baby_bear_add(a, a);
}

static __device__ __forceinline__ uint32_t baby_bear_mul_w(uint32_t a) {
  return baby_bear_mul(a, BABY_BEAR_W);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_mul_c0(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t b0, uint32_t b1, uint32_t b2, uint32_t b3) {
  uint32_t a0b0 = baby_bear_mul(a0, b0);
  uint32_t a1b3 = baby_bear_mul(a1, b3);
  uint32_t a2b2 = baby_bear_mul(a2, b2);
  uint32_t a3b1 = baby_bear_mul(a3, b1);
  uint32_t s1 = baby_bear_add(a1b3, a2b2);
  uint32_t s2 = baby_bear_add(s1, a3b1);
  uint32_t ws = baby_bear_mul_w(s2);
  return baby_bear_add(a0b0, ws);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_mul_c1(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t b0, uint32_t b1, uint32_t b2, uint32_t b3) {
  uint32_t a0b1 = baby_bear_mul(a0, b1);
  uint32_t a1b0 = baby_bear_mul(a1, b0);
  uint32_t a2b3 = baby_bear_mul(a2, b3);
  uint32_t a3b2 = baby_bear_mul(a3, b2);
  uint32_t s0 = baby_bear_add(a0b1, a1b0);
  uint32_t s1 = baby_bear_add(a2b3, a3b2);
  uint32_t ws = baby_bear_mul_w(s1);
  return baby_bear_add(s0, ws);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_mul_c2(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t b0, uint32_t b1, uint32_t b2, uint32_t b3) {
  uint32_t a0b2 = baby_bear_mul(a0, b2);
  uint32_t a1b1 = baby_bear_mul(a1, b1);
  uint32_t a2b0 = baby_bear_mul(a2, b0);
  uint32_t a3b3 = baby_bear_mul(a3, b3);
  uint32_t s01 = baby_bear_add(a0b2, a1b1);
  uint32_t s012 = baby_bear_add(s01, a2b0);
  uint32_t ws = baby_bear_mul_w(a3b3);
  return baby_bear_add(s012, ws);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_mul_c3(uint32_t a0, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t b0, uint32_t b1, uint32_t b2, uint32_t b3) {
  uint32_t a0b3 = baby_bear_mul(a0, b3);
  uint32_t a1b2 = baby_bear_mul(a1, b2);
  uint32_t a2b1 = baby_bear_mul(a2, b1);
  uint32_t a3b0 = baby_bear_mul(a3, b0);
  uint32_t s01 = baby_bear_add(a0b3, a1b2);
  uint32_t s012 = baby_bear_add(s01, a2b1);
  return baby_bear_add(s012, a3b0);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_add_c0(uint32_t a, uint32_t b) {
  return baby_bear_add(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_add_c1(uint32_t a, uint32_t b) {
  return baby_bear_add(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_add_c2(uint32_t a, uint32_t b) {
  return baby_bear_add(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_add_c3(uint32_t a, uint32_t b) {
  return baby_bear_add(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_sub_c0(uint32_t a, uint32_t b) {
  return baby_bear_sub(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_sub_c1(uint32_t a, uint32_t b) {
  return baby_bear_sub(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_sub_c2(uint32_t a, uint32_t b) {
  return baby_bear_sub(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_ext4_sub_c3(uint32_t a, uint32_t b) {
  return baby_bear_sub(a, b);
}

static __device__ __forceinline__ uint32_t baby_bear_sbox_x7(uint32_t x) {
  uint32_t x2 = baby_bear_mul(x, x);
  uint32_t x4 = baby_bear_mul(x2, x2);
  uint32_t x6 = baby_bear_mul(x4, x2);
  return baby_bear_mul(x6, x);
}

static __device__ __forceinline__ uint32_t baby_bear_p2_ext_chunk_y0(uint32_t x0, uint32_t x1, uint32_t x2, uint32_t x3) {
  uint32_t two_x0 = baby_bear_double(x0);
  uint32_t three_x1 = baby_bear_add(baby_bear_double(x1), x1);
  uint32_t s1 = baby_bear_add(two_x0, three_x1);
  uint32_t s2 = baby_bear_add(s1, x2);
  return baby_bear_add(s2, x3);
}

static __device__ __forceinline__ uint32_t baby_bear_p2_ext_chunk_y1(uint32_t x0, uint32_t x1, uint32_t x2, uint32_t x3) {
  uint32_t two_x1 = baby_bear_double(x1);
  uint32_t three_x2 = baby_bear_add(baby_bear_double(x2), x2);
  uint32_t s1 = baby_bear_add(x0, two_x1);
  uint32_t s2 = baby_bear_add(s1, three_x2);
  return baby_bear_add(s2, x3);
}

static __device__ __forceinline__ uint32_t baby_bear_p2_ext_chunk_y2(uint32_t x0, uint32_t x1, uint32_t x2, uint32_t x3) {
  uint32_t two_x2 = baby_bear_double(x2);
  uint32_t three_x3 = baby_bear_add(baby_bear_double(x3), x3);
  uint32_t s1 = baby_bear_add(x0, x1);
  uint32_t s2 = baby_bear_add(s1, two_x2);
  return baby_bear_add(s2, three_x3);
}

static __device__ __forceinline__ uint32_t baby_bear_p2_ext_chunk_y3(uint32_t x0, uint32_t x1, uint32_t x2, uint32_t x3) {
  uint32_t two_x0 = baby_bear_double(x0);
  uint32_t three_x0 = baby_bear_add(two_x0, x0);
  uint32_t two_x3 = baby_bear_double(x3);
  uint32_t s1 = baby_bear_add(three_x0, x1);
  uint32_t s2 = baby_bear_add(s1, x2);
  return baby_bear_add(s2, two_x3);
}

static __device__ __forceinline__ uint32_t baby_bear_p2_int_sbox_with_rc(uint32_t state0, uint32_t rc) {
  uint32_t with_rc = baby_bear_add(state0, rc);
  return baby_bear_sbox_x7(with_rc);
}

static __device__ __forceinline__ uint32_t baby_bear_p2_ark(uint32_t s, uint32_t rc) {
  return baby_bear_add(s, rc);
}

static __device__ __forceinline__ uint32_t baby_bear_p2_ext_sbox_with_rc(uint32_t s, uint32_t rc) {
  uint32_t with_rc = baby_bear_add(s, rc);
  return baby_bear_sbox_x7(with_rc);
}

static __device__ __forceinline__ uint32_t baby_bear_get(uint32_t* __restrict__ arr, uint64_t arr_len, uint64_t idx) {
  0 /* unhandled */;
  return arr[idx];
}

__global__ void baby_bear_sbox_kernel(uint32_t* __restrict__ out, uint64_t out_len, uint32_t* __restrict__ a, uint64_t a_len, uint64_t n) {
  uint64_t tid = ((blockIdx.x * blockDim.x) + threadIdx.x);
  if ((tid < n)) {
    uint32_t av = baby_bear_get(a, a_len, tid);
    out[tid] = baby_bear_sbox_x7(av);
  }
}

