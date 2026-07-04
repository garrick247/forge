// bench_mds.cu — perf validation for the verified Poseidon2 MDS kernel
// (demos/1158_poseidon2_mds_verified.fg, poseidon2_mds3_at).
//
// MDS circ(2,1,1) over width-3 states: out_i = 2*s_i + sum_{j!=i} s_j (mod P).
// It uses ONLY m31_add / m31_double (no field mul), so the `% M31_P` reduction --
// the only place forge's "for provability" cost lives -- never appears: the
// verified emit is bit-identical to a hand-tuned Mersenne implementation by
// construction (M31 add is a conditional subtract either way). So this benchmark
// reports absolute throughput / memory roofline; the verified-vs-fast ratio is
// 1.000 trivially. 24 bytes/state (3 u32 read + 3 u32 write).
//
// Measured on an RTX 5090 (sm_120, CUDA 13.3, 500W cap), 300 timed iters:
//   logN=28 (VRAM, 3 GB):  4.223 ms  63.6 G-state/s  1526 GB/s  (~85% roofline)
//   logN=24 (192 MB):      0.264 ms  63.6 G-state/s  1527 GB/s
// Memory-bound at ~85% of the 5090's ~1.79 TB/s, consistent across sizes; the
// verified Poseidon2 diffusion runs at the memory ceiling.
//
// Build/run:  nvcc -O3 -arch=sm_120 bench_mds.cu -o bench_mds
//             ./bench_mds [logN]     # default 24; N = number of width-3 states
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

static const uint32_t M31_P = 2147483647U;

// emitted m31 add (conditional subtract); double = add(a,a)
static __device__ __forceinline__ uint32_t v_add(uint32_t a, uint32_t b){
  uint64_t s=(uint64_t)a+(uint64_t)b, p=(uint64_t)M31_P, r; if(s>=p) r=s-p; else r=s; return (uint32_t)r; }
static __device__ __forceinline__ uint32_t v_dbl(uint32_t a){ return v_add(a,a); }

__global__ void mds_verified(uint32_t* __restrict__ st, uint64_t n){
  uint64_t tid=(uint64_t)blockIdx.x*blockDim.x+threadIdx.x;
  if(tid<n){ uint64_t b=3*tid; uint32_t s0=st[b], s1=st[b+1], s2=st[b+2];
    st[b]   = v_add(v_dbl(s0), v_add(s1,s2));
    st[b+1] = v_add(v_dbl(s1), v_add(s0,s2));
    st[b+2] = v_add(v_dbl(s2), v_add(s0,s1)); } }

int main(int argc, char** argv){
  uint64_t logN = argc>1? strtoull(argv[1],0,10):24;
  uint64_t n=1ull<<logN, len=3*n;
  uint32_t *st;
  cudaMalloc(&st, len*4);
  uint32_t* h=(uint32_t*)malloc(len*4);
  for(uint64_t i=0;i<len;i++) h[i]=(uint32_t)(((i*2654435761ull)+11ull)%M31_P);
  cudaMemcpy(st,h,len*4,cudaMemcpyHostToDevice);
  int bs=256; uint64_t grid=(n+bs-1)/bs;
  cudaEvent_t s,e; cudaEventCreate(&s); cudaEventCreate(&e); const int K=300;
  for(int w=0;w<30;w++) mds_verified<<<grid,bs>>>(st,n); cudaDeviceSynchronize();
  cudaEventRecord(s); for(int k=0;k<K;k++) mds_verified<<<grid,bs>>>(st,n);
  cudaEventRecord(e); cudaEventSynchronize(e);
  float ms; cudaEventElapsedTime(&ms,s,e); ms/=K;
  double bytes=(double)n*24.0;
  printf("logN=%llu  states=%llu\n",(unsigned long long)logN,(unsigned long long)n);
  printf("MDS verified  %.4f ms  %6.2f G-state/s  %7.1f GB/s\n",
    ms, ((double)n/(ms/1e3))/1e9, (bytes/(ms/1e3))/1e9);
  cudaError_t err=cudaGetLastError(); if(err) printf("CUDA err: %s\n",cudaGetErrorString(err));
  return 0;
}
