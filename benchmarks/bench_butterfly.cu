// bench_butterfly.cu — perf validation for the verified in-place NTT butterfly
// (demos/1153_ntt_butterfly_verified.fg).
//
// Question: does the kernel Forge PROVED correct pay a speed penalty for keeping
// the M31 reduction as `% M31_P` (done for provability) instead of the branchless
// Mersenne fold? Answer: essentially no.
//
// Method: the "verified" path uses the M31 device functions emitted VERBATIM by
// `forge cuda` for demo 1153 (m31_mul via `%`, conditional add/sub, butterfly_hi/lo).
// The "fast" path is a hand-optimized Mersenne-fold butterfly. Both are launched as
// one in-place NTT stage (tid = blockIdx*blockDim+threadIdx, one thread per pair;
// the verified kernel takes tid as a param for Forge's SPMD proof model, so here we
// drive the identical compute from the thread index). 20 bytes moved per butterfly
// (2 data + 1 twiddle read, 2 data write).
//
// Measured on an RTX 5090 (sm_120, CUDA 13.3, 500W cap), 300 timed iters:
//
//   size                        verified            fast          verified/fast
//   logN=28 (VRAM, ~1.5GB)   1.729 ms / 1553 GB/s  1.727 / 1554     1.001
//   logN=24 (L2, ~100MB)     0.037 ms / 4498 GB/s  0.036 / 4651     1.034
//   correctness: 0 mismatches vs the hand-optimized path at both sizes.
//
// Takeaway: at VRAM-bound scale (the realistic regime) the verified kernel is
// performance-identical to hand-tuned (0.1%) and runs at ~87% of the 5090's memory
// roofline — the `%`-for-provability compute hides fully behind memory bandwidth.
// The only measurable cost (~3.4%) appears only when the working set fits in L2 and
// compute becomes the bottleneck. Verification is free where it counts.
//
// Build/run:  nvcc -O3 -arch=sm_120 bench_butterfly.cu -o bench_butterfly
//             ./bench_butterfly [logN]     # default logN=24

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

static const uint32_t M31_P = 2147483647U;

// ---------- verified path: device fns copied VERBATIM from forge output ----------
static __device__ __forceinline__ uint32_t v_mul(uint32_t a, uint32_t b){
  uint64_t prod = ((uint64_t)a) * ((uint64_t)b);
  uint64_t p = (uint64_t)M31_P;
  uint64_t r = prod % p;
  return (uint32_t)r;
}
static __device__ __forceinline__ uint32_t v_add(uint32_t a, uint32_t b){
  uint64_t s = (uint64_t)a + (uint64_t)b; uint64_t p = (uint64_t)M31_P;
  uint64_t r; if (s >= p) r = s - p; else r = s; return (uint32_t)r;
}
static __device__ __forceinline__ uint32_t v_sub(uint32_t a, uint32_t b){
  uint64_t a64 = a, b64 = b, p = (uint64_t)M31_P, r;
  if (a64 >= b64) r = a64 - b64; else r = (a64 + p) - b64; return (uint32_t)r;
}
static __device__ __forceinline__ uint32_t v_bhi(uint32_t a, uint32_t b, uint32_t w){ uint32_t t=v_mul(w,b); return v_add(a,t); }
static __device__ __forceinline__ uint32_t v_blo(uint32_t a, uint32_t b, uint32_t w){ uint32_t t=v_mul(w,b); return v_sub(a,t); }

// ---------- fast path: hand-optimized Mersenne fold ----------
static __device__ __forceinline__ uint32_t f_mul(uint32_t a, uint32_t b){
  uint64_t p = (uint64_t)a * (uint64_t)b;
  uint32_t lo = (uint32_t)(p & M31_P);
  uint32_t hi = (uint32_t)(p >> 31);
  uint32_t r = lo + hi;                 // < 2P
  return r >= M31_P ? r - M31_P : r;
}
static __device__ __forceinline__ uint32_t f_add(uint32_t a, uint32_t b){ uint32_t r=a+b; return r>=M31_P? r-M31_P : r; }
static __device__ __forceinline__ uint32_t f_sub(uint32_t a, uint32_t b){ return a>=b? a-b : a+M31_P-b; }
static __device__ __forceinline__ uint32_t f_bhi(uint32_t a, uint32_t b, uint32_t w){ uint32_t t=f_mul(w,b); return f_add(a,t); }
static __device__ __forceinline__ uint32_t f_blo(uint32_t a, uint32_t b, uint32_t w){ uint32_t t=f_mul(w,b); return f_sub(a,t); }

__global__ void stage_verified(uint32_t* __restrict__ data, const uint32_t* __restrict__ tw, uint64_t half_n){
  uint64_t tid = (uint64_t)blockIdx.x*blockDim.x + threadIdx.x;
  if (tid < half_n){ uint32_t a=data[tid], b=data[tid+half_n], w=tw[tid];
    data[tid]=v_bhi(a,b,w); data[tid+half_n]=v_blo(a,b,w); }
}
__global__ void stage_fast(uint32_t* __restrict__ data, const uint32_t* __restrict__ tw, uint64_t half_n){
  uint64_t tid = (uint64_t)blockIdx.x*blockDim.x + threadIdx.x;
  if (tid < half_n){ uint32_t a=data[tid], b=data[tid+half_n], w=tw[tid];
    data[tid]=f_bhi(a,b,w); data[tid+half_n]=f_blo(a,b,w); }
}

int main(int argc, char** argv){
  uint64_t logN = argc>1 ? strtoull(argv[1],0,10) : 24;
  uint64_t N=1ull<<logN, half=N/2;
  uint32_t *d0,*dv,*df,*dtw;
  cudaMalloc(&d0,N*4); cudaMalloc(&dv,N*4); cudaMalloc(&df,N*4); cudaMalloc(&dtw,half*4);
  uint32_t* h=(uint32_t*)malloc(N*4);
  for(uint64_t i=0;i<N;i++)   h[i]=(uint32_t)(((i*2654435761ull)+11ull)%M31_P);
  cudaMemcpy(d0,h,N*4,cudaMemcpyHostToDevice);
  uint32_t* ht=(uint32_t*)malloc(half*4);
  for(uint64_t i=0;i<half;i++) ht[i]=(uint32_t)(((i*40503ull)+7ull)%M31_P);
  cudaMemcpy(dtw,ht,half*4,cudaMemcpyHostToDevice);

  int bs=256; uint64_t grid=(half+bs-1)/bs;

  // ---- correctness: verified vs fast on identical fresh input ----
  cudaMemcpy(dv,d0,N*4,cudaMemcpyDeviceToDevice);
  cudaMemcpy(df,d0,N*4,cudaMemcpyDeviceToDevice);
  stage_verified<<<grid,bs>>>(dv,dtw,half);
  stage_fast    <<<grid,bs>>>(df,dtw,half);
  cudaDeviceSynchronize();
  uint32_t *hv=(uint32_t*)malloc(N*4), *hf=(uint32_t*)malloc(N*4);
  cudaMemcpy(hv,dv,N*4,cudaMemcpyDeviceToHost);
  cudaMemcpy(hf,df,N*4,cudaMemcpyDeviceToHost);
  uint64_t mism=0; for(uint64_t i=0;i<N;i++) if(hv[i]!=hf[i]) mism++;
  printf("correctness: verified vs fast mismatches = %llu / %llu\n",(unsigned long long)mism,(unsigned long long)N);

  cudaEvent_t s,e; cudaEventCreate(&s); cudaEventCreate(&e);
  const int K=300;
  auto bench=[&](void(*kern)(uint32_t*,const uint32_t*,uint64_t))->float{
    cudaMemcpy(dv,d0,N*4,cudaMemcpyDeviceToDevice);
    for(int w=0;w<30;w++) kern<<<grid,bs>>>(dv,dtw,half);
    cudaDeviceSynchronize();
    cudaEventRecord(s);
    for(int k=0;k<K;k++) kern<<<grid,bs>>>(dv,dtw,half);
    cudaEventRecord(e); cudaEventSynchronize(e);
    float ms; cudaEventElapsedTime(&ms,s,e); return ms/K;
  };
  float mv=bench(stage_verified), mf=bench(stage_fast);
  double bytes=(double)half*20.0; // 12B read (2 data + 1 tw) + 8B write (2 data)
  auto rep=[&](const char*n,float ms){
    printf("%-9s %.4f ms/stage  %6.2f G-butterfly/s  %7.1f GB/s\n",
      n,ms,((double)half/(ms/1e3))/1e9,(bytes/(ms/1e3))/1e9);
  };
  printf("logN=%llu  N=%llu  butterflies/stage=%llu\n",(unsigned long long)logN,(unsigned long long)N,(unsigned long long)half);
  rep("verified",mv); rep("fast",mf);
  printf("verified/fast time ratio: %.3f  (1.00 = identical; >1 = verified slower)\n", mv/mf);
  cudaError_t err=cudaGetLastError(); if(err) printf("CUDA err: %s\n",cudaGetErrorString(err));
  return 0;
}
