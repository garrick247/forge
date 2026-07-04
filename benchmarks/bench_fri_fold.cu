// bench_fri_fold.cu — perf validation for the verified FRI fold
// (demos/1154_fri_fold_verified.fg).
//
// FRI fold:  new[i] = old[i] + alpha * old[i+half]   (mod P), out-of-place.
// "verified" path = M31 device fns emitted verbatim by forge cuda (% M31_P
// reduction, kept for provability); "fast" path = hand-optimized Mersenne fold.
// Also benchmarks the CM31 (complex extension) fold that stwo runs.
// Bytes/output: M31 fold = 12 (2 reads + 1 write); CM31 fold = 24 (4 reads + 2 writes).
//
// Measured on an RTX 5090 (sm_120, CUDA 13.3, 500W cap), 300 timed iters:
//
//   size                     M31 verified        M31 fast       verified/fast   CM31 verified
//   logN=28 (VRAM)        1.020 ms / 1580 GB/s  1.019 / 1580        1.000       2.046 ms / 1575 GB/s
//   logN=24 (L2)          0.026 ms / 3881 GB/s  0.025 / 4060        1.046       0.117 ms / 1727 GB/s
//   correctness: 0 mismatches (M31 verified vs fast) at both sizes.
//
// Takeaway (same as the NTT butterfly, benchmarks/bench_butterfly.cu): at
// VRAM-bound scale the verified fold is identical to hand-tuned (ratio 1.000),
// both at ~1580 GB/s (~88% of roofline); the `%`-for-provability cost (~4.6%)
// shows only in the L2/compute-bound regime. The CM31 extension fold is ALSO
// memory-bound (same ~1575 GB/s ceiling, half the folds/s since it moves 24 B vs
// 12 B), so even the complex-multiply compute hides fully behind memory.
//
// Build/run:  nvcc -O3 -arch=sm_120 bench_fri_fold.cu -o bench_fri_fold
//             ./bench_fri_fold [logN]     # default 24
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

static const uint32_t M31_P = 2147483647U;

// ---- verified path (emitted verbatim by forge) ----
static __device__ __forceinline__ uint32_t v_mul(uint32_t a, uint32_t b){
  uint64_t prod=((uint64_t)a)*((uint64_t)b); uint64_t p=(uint64_t)M31_P; return (uint32_t)(prod%p); }
static __device__ __forceinline__ uint32_t v_add(uint32_t a, uint32_t b){
  uint64_t s=(uint64_t)a+(uint64_t)b, p=(uint64_t)M31_P, r; if(s>=p) r=s-p; else r=s; return (uint32_t)r; }
static __device__ __forceinline__ uint32_t v_sub(uint32_t a, uint32_t b){
  uint64_t a64=a,b64=b,p=(uint64_t)M31_P,r; if(a64>=b64) r=a64-b64; else r=(a64+p)-b64; return (uint32_t)r; }
static __device__ __forceinline__ uint32_t v_cmre(uint32_t ar,uint32_t ai,uint32_t br,uint32_t bi){
  return v_sub(v_mul(ar,br), v_mul(ai,bi)); }
static __device__ __forceinline__ uint32_t v_cmim(uint32_t ar,uint32_t ai,uint32_t br,uint32_t bi){
  return v_add(v_mul(ar,bi), v_mul(ai,br)); }

// ---- fast path (Mersenne fold) ----
static __device__ __forceinline__ uint32_t f_mul(uint32_t a, uint32_t b){
  uint64_t p=(uint64_t)a*(uint64_t)b; uint32_t lo=(uint32_t)(p&M31_P), hi=(uint32_t)(p>>31), r=lo+hi;
  return r>=M31_P? r-M31_P : r; }
static __device__ __forceinline__ uint32_t f_add(uint32_t a, uint32_t b){ uint32_t r=a+b; return r>=M31_P? r-M31_P:r; }

__global__ void fri_verified(uint32_t* __restrict__ ne, const uint32_t* __restrict__ oe, uint32_t alpha, uint64_t half){
  uint64_t i=(uint64_t)blockIdx.x*blockDim.x+threadIdx.x;
  if(i<half) ne[i]=v_add(oe[i], v_mul(alpha, oe[i+half])); }
__global__ void fri_fast(uint32_t* __restrict__ ne, const uint32_t* __restrict__ oe, uint32_t alpha, uint64_t half){
  uint64_t i=(uint64_t)blockIdx.x*blockDim.x+threadIdx.x;
  if(i<half) ne[i]=f_add(oe[i], f_mul(alpha, oe[i+half])); }
__global__ void fri_cm31_verified(uint32_t* __restrict__ nr, uint32_t* __restrict__ ni,
    const uint32_t* __restrict__ orr, const uint32_t* __restrict__ oi, uint32_t ar, uint32_t ai, uint64_t half){
  uint64_t i=(uint64_t)blockIdx.x*blockDim.x+threadIdx.x;
  if(i<half){ uint32_t br=orr[i+half], bi=oi[i+half];
    nr[i]=v_add(orr[i], v_cmre(ar,ai,br,bi)); ni[i]=v_add(oi[i], v_cmim(ar,ai,br,bi)); } }

int main(int argc, char** argv){
  uint64_t logN = argc>1? strtoull(argv[1],0,10):24;
  uint64_t N=1ull<<logN, half=N/2;
  uint32_t *oe,*ne,*ne2,*oi,*ni; // old(2*half), new(half) x2 for M31 v/f; plus imag for cm31
  cudaMalloc(&oe,N*4); cudaMalloc(&ne,half*4); cudaMalloc(&ne2,half*4);
  cudaMalloc(&oi,N*4); cudaMalloc(&ni,half*4);
  uint32_t* h=(uint32_t*)malloc(N*4);
  for(uint64_t i=0;i<N;i++) h[i]=(uint32_t)(((i*2654435761ull)+11ull)%M31_P);
  cudaMemcpy(oe,h,N*4,cudaMemcpyHostToDevice); cudaMemcpy(oi,h,N*4,cudaMemcpyHostToDevice);
  uint32_t alpha=(uint32_t)(1234567ull%M31_P), ai=(uint32_t)(7654321ull%M31_P);
  int bs=256; uint64_t grid=(half+bs-1)/bs;

  // correctness: verified vs fast (M31)
  fri_verified<<<grid,bs>>>(ne, oe, alpha, half);
  fri_fast    <<<grid,bs>>>(ne2,oe, alpha, half);
  cudaDeviceSynchronize();
  uint32_t *hv=(uint32_t*)malloc(half*4), *hf=(uint32_t*)malloc(half*4);
  cudaMemcpy(hv,ne,half*4,cudaMemcpyDeviceToHost); cudaMemcpy(hf,ne2,half*4,cudaMemcpyDeviceToHost);
  uint64_t mism=0; for(uint64_t i=0;i<half;i++) if(hv[i]!=hf[i]) mism++;
  printf("correctness: M31 verified vs fast mismatches = %llu / %llu\n",(unsigned long long)mism,(unsigned long long)half);

  cudaEvent_t s,e; cudaEventCreate(&s); cudaEventCreate(&e); const int K=300;
  auto time_m31=[&](void(*k)(uint32_t*,const uint32_t*,uint32_t,uint64_t))->float{
    for(int w=0;w<30;w++) k<<<grid,bs>>>(ne,oe,alpha,half); cudaDeviceSynchronize();
    cudaEventRecord(s); for(int j=0;j<K;j++) k<<<grid,bs>>>(ne,oe,alpha,half);
    cudaEventRecord(e); cudaEventSynchronize(e); float ms; cudaEventElapsedTime(&ms,s,e); return ms/K; };
  float mv=time_m31(fri_verified), mf=time_m31(fri_fast);
  // cm31
  for(int w=0;w<30;w++) fri_cm31_verified<<<grid,bs>>>(ne,ni,oe,oi,alpha,ai,half); cudaDeviceSynchronize();
  cudaEventRecord(s); for(int j=0;j<K;j++) fri_cm31_verified<<<grid,bs>>>(ne,ni,oe,oi,alpha,ai,half);
  cudaEventRecord(e); cudaEventSynchronize(e); float mc; cudaEventElapsedTime(&mc,s,e); mc/=K;

  printf("logN=%llu  folds/stage=%llu\n",(unsigned long long)logN,(unsigned long long)half);
  auto rep=[&](const char*n,float ms,double bpo){ printf("%-14s %.4f ms  %6.2f G-fold/s  %7.1f GB/s\n",
     n, ms, ((double)half/(ms/1e3))/1e9, ((double)half*bpo/(ms/1e3))/1e9); };
  rep("M31 verified", mv, 12.0); rep("M31 fast", mf, 12.0);
  printf("M31 verified/fast time ratio: %.3f\n", mv/mf);
  rep("CM31 verified", mc, 24.0);
  cudaError_t err=cudaGetLastError(); if(err) printf("CUDA err: %s\n",cudaGetErrorString(err));
  return 0;
}
