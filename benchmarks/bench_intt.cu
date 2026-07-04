// bench_intt.cu — perf validation for the verified Gentleman-Sande INTT butterfly
// (demos/1155_intt_butterfly_verified.fg).
//
// GS INTT butterfly (in-place):  a' = a + b,  b' = w*(a - b)   (mod P).
// "verified" path = M31 device fns emitted verbatim by forge cuda (% M31_P, kept
// for provability); "fast" = hand-optimized Mersenne fold. 20 bytes/butterfly
// (2 data + 1 twiddle read, 2 data write). Companion to bench_butterfly.cu.
//
// Measured on an RTX 5090 (sm_120, CUDA 13.3, 500W cap), 300 timed iters:
//
//   size                     verified            fast          verified/fast
//   logN=28 (VRAM)        1.726 ms / 1555 GB/s  1.726 / 1556     1.000
//   logN=24 (L2)          0.039 ms / 4353 GB/s  0.037 / 4581     1.052
//   correctness: 0 mismatches vs the hand-optimized path at both sizes.
//
// Same result as the forward butterfly (bench_butterfly.cu): at VRAM-bound scale
// the verified GS INTT butterfly is identical to hand-tuned (ratio 1.000, ~1555
// GB/s, ~87% of roofline); the `%`-for-provability cost (~5%) shows only in the
// L2/compute-bound regime.
//
// Build/run:  nvcc -O3 -arch=sm_120 bench_intt.cu -o bench_intt
//             ./bench_intt [logN]     # default 24
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

// ---- fast path (Mersenne fold) ----
static __device__ __forceinline__ uint32_t f_mul(uint32_t a, uint32_t b){
  uint64_t p=(uint64_t)a*(uint64_t)b; uint32_t lo=(uint32_t)(p&M31_P), hi=(uint32_t)(p>>31), r=lo+hi;
  return r>=M31_P? r-M31_P : r; }
static __device__ __forceinline__ uint32_t f_add(uint32_t a, uint32_t b){ uint32_t r=a+b; return r>=M31_P? r-M31_P:r; }
static __device__ __forceinline__ uint32_t f_sub(uint32_t a, uint32_t b){ return a>=b? a-b : a+M31_P-b; }

__global__ void gs_verified(uint32_t* __restrict__ data, const uint32_t* __restrict__ tw, uint64_t half){
  uint64_t i=(uint64_t)blockIdx.x*blockDim.x+threadIdx.x;
  if(i<half){ uint32_t a=data[i], b=data[i+half], w=tw[i];
    data[i]=v_add(a,b); data[i+half]=v_mul(w, v_sub(a,b)); } }
__global__ void gs_fast(uint32_t* __restrict__ data, const uint32_t* __restrict__ tw, uint64_t half){
  uint64_t i=(uint64_t)blockIdx.x*blockDim.x+threadIdx.x;
  if(i<half){ uint32_t a=data[i], b=data[i+half], w=tw[i];
    data[i]=f_add(a,b); data[i+half]=f_mul(w, f_sub(a,b)); } }

int main(int argc, char** argv){
  uint64_t logN = argc>1? strtoull(argv[1],0,10):24;
  uint64_t N=1ull<<logN, half=N/2;
  uint32_t *d0,*dv,*df,*dtw;
  cudaMalloc(&d0,N*4); cudaMalloc(&dv,N*4); cudaMalloc(&df,N*4); cudaMalloc(&dtw,half*4);
  uint32_t* h=(uint32_t*)malloc(N*4);
  for(uint64_t i=0;i<N;i++) h[i]=(uint32_t)(((i*2654435761ull)+11ull)%M31_P);
  cudaMemcpy(d0,h,N*4,cudaMemcpyHostToDevice);
  uint32_t* ht=(uint32_t*)malloc(half*4);
  for(uint64_t i=0;i<half;i++) ht[i]=(uint32_t)(((i*40503ull)+7ull)%M31_P);
  cudaMemcpy(dtw,ht,half*4,cudaMemcpyHostToDevice);
  int bs=256; uint64_t grid=(half+bs-1)/bs;

  // correctness on identical fresh input
  cudaMemcpy(dv,d0,N*4,cudaMemcpyDeviceToDevice);
  cudaMemcpy(df,d0,N*4,cudaMemcpyDeviceToDevice);
  gs_verified<<<grid,bs>>>(dv,dtw,half);
  gs_fast    <<<grid,bs>>>(df,dtw,half);
  cudaDeviceSynchronize();
  uint32_t *hv=(uint32_t*)malloc(N*4), *hf=(uint32_t*)malloc(N*4);
  cudaMemcpy(hv,dv,N*4,cudaMemcpyDeviceToHost); cudaMemcpy(hf,df,N*4,cudaMemcpyDeviceToHost);
  uint64_t mism=0; for(uint64_t i=0;i<N;i++) if(hv[i]!=hf[i]) mism++;
  printf("correctness: verified vs fast mismatches = %llu / %llu\n",(unsigned long long)mism,(unsigned long long)N);

  cudaEvent_t s,e; cudaEventCreate(&s); cudaEventCreate(&e); const int K=300;
  auto bench=[&](void(*kern)(uint32_t*,const uint32_t*,uint64_t))->float{
    cudaMemcpy(dv,d0,N*4,cudaMemcpyDeviceToDevice);
    for(int w=0;w<30;w++) kern<<<grid,bs>>>(dv,dtw,half); cudaDeviceSynchronize();
    cudaEventRecord(s); for(int k=0;k<K;k++) kern<<<grid,bs>>>(dv,dtw,half);
    cudaEventRecord(e); cudaEventSynchronize(e); float ms; cudaEventElapsedTime(&ms,s,e); return ms/K; };
  float mv=bench(gs_verified), mf=bench(gs_fast);
  double bytes=(double)half*20.0;
  auto rep=[&](const char*n,float ms){ printf("%-9s %.4f ms/stage  %6.2f G-butterfly/s  %7.1f GB/s\n",
    n,ms,((double)half/(ms/1e3))/1e9,(bytes/(ms/1e3))/1e9); };
  printf("logN=%llu  butterflies/stage=%llu\n",(unsigned long long)logN,(unsigned long long)half);
  rep("verified",mv); rep("fast",mf);
  printf("verified/fast time ratio: %.3f  (1.00 = identical; >1 = verified slower)\n", mv/mf);
  cudaError_t err=cudaGetLastError(); if(err) printf("CUDA err: %s\n",cudaGetErrorString(err));
  return 0;
}
