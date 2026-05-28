// Differential harness: forge eval kernels vs hand fold kernels, identical input.
#include <cuda_runtime.h>
#include <cstdio>
#include <cstdint>
#include <random>
#include "/home/garrick/VortexSTARK/cuda/include/qm31.cuh"

static const uint32_t P = 2147483647u;

// forge kernels live in eval_at_point.cu (separate TU); declare them.
__global__ void eval_fold_first(uint32_t* coeffs, uint64_t coeffs_len, uint32_t* out, uint64_t out_len, uint32_t fa, uint32_t fb, uint32_t fc, uint32_t fd, uint64_t half_n);
__global__ void eval_fold_level(uint32_t* in_data, uint64_t in_len, uint32_t* out_data, uint64_t out_len, uint32_t fa, uint32_t fb, uint32_t fc, uint32_t fd, uint64_t half_n);

// hand kernels copied verbatim from cuda/circle_ntt.cu
__global__ void hand_fold_first(const uint32_t* __restrict__ coeffs, uint32_t* __restrict__ out, const uint32_t* __restrict__ factor, uint32_t half_n){
  uint32_t tid=blockIdx.x*blockDim.x+threadIdx.x; if(tid>=half_n) return;
  uint32_t a=coeffs[tid]; uint32_t b=coeffs[tid+half_n];
  QM31 f={{factor[0],factor[1],factor[2],factor[3]}};
  QM31 bf=qm31_mul_m31(f,b);
  QM31 r={{m31_add(a,bf.v[0]),bf.v[1],bf.v[2],bf.v[3]}};
  out[tid*4+0]=r.v[0]; out[tid*4+1]=r.v[1]; out[tid*4+2]=r.v[2]; out[tid*4+3]=r.v[3];
}
__global__ void hand_fold_level(const uint32_t* __restrict__ in_data, uint32_t* __restrict__ out_data, const uint32_t* __restrict__ factor, uint32_t half_n){
  uint32_t tid=blockIdx.x*blockDim.x+threadIdx.x; if(tid>=half_n) return;
  uint32_t ai=tid*4; uint32_t bi=(tid+half_n)*4;
  QM31 a={{in_data[ai],in_data[ai+1],in_data[ai+2],in_data[ai+3]}};
  QM31 b={{in_data[bi],in_data[bi+1],in_data[bi+2],in_data[bi+3]}};
  QM31 f={{factor[0],factor[1],factor[2],factor[3]}};
  QM31 r=qm31_add(a,qm31_mul(b,f));
  out_data[tid*4+0]=r.v[0]; out_data[tid*4+1]=r.v[1]; out_data[tid*4+2]=r.v[2]; out_data[tid*4+3]=r.v[3];
}

#define CK(x) do{cudaError_t e=(x); if(e!=cudaSuccess){printf("CUDA err %s:%d %s\n",__FILE__,__LINE__,cudaGetErrorString(e)); return 2;}}while(0)
int run(bool use_forge,const uint32_t* d_coeffs,const uint32_t* h_fac,const uint32_t* d_fac,uint32_t n,uint32_t* s1,uint32_t* s2,uint32_t* out){
  uint32_t threads=256; uint32_t log_n=0; for(uint32_t t=n;t>1;t>>=1) log_n++;
  uint32_t half_n=n/2; uint32_t blocks=(half_n+threads-1)/threads;
  if(use_forge) eval_fold_first<<<blocks,threads>>>((uint32_t*)d_coeffs,n,s1,(uint64_t)half_n*4,h_fac[0],h_fac[1],h_fac[2],h_fac[3],half_n);
  else hand_fold_first<<<blocks,threads>>>(d_coeffs,s1,d_fac,half_n);
  CK(cudaDeviceSynchronize());
  uint32_t* inb=s1; uint32_t* outb=s2; uint32_t cur=half_n;
  for(uint32_t lv=1; lv<log_n; lv++){
    half_n=cur/2; blocks=(half_n+threads-1)/threads;
    if(use_forge) eval_fold_level<<<blocks,threads>>>(inb,(uint64_t)cur*4,outb,(uint64_t)half_n*4,h_fac[lv*4+0],h_fac[lv*4+1],h_fac[lv*4+2],h_fac[lv*4+3],half_n);
    else hand_fold_level<<<blocks,threads>>>(inb,outb,d_fac+lv*4,half_n);
    CK(cudaDeviceSynchronize());
    uint32_t* tmp=inb; inb=outb; outb=tmp; cur=half_n;
  }
  CK(cudaMemcpy(out,inb,4*sizeof(uint32_t),cudaMemcpyDeviceToHost)); return 0;
}
int main(){
  uint32_t log_n=12; uint32_t n=1u<<log_n;
  std::mt19937 rng(12345); 
  uint32_t* h_coeffs=new uint32_t[n]; for(uint32_t i=0;i<n;i++) h_coeffs[i]=rng()%P;
  uint32_t* h_fac=new uint32_t[log_n*4]; for(uint32_t i=0;i<log_n*4;i++) h_fac[i]=rng()%P;
  uint32_t *d_coeffs,*d_fac,*s1a,*s2a,*s1b,*s2b;
  CK(cudaMalloc(&d_coeffs,n*4)); CK(cudaMalloc(&d_fac,log_n*4*4));
  CK(cudaMalloc(&s1a,n*4*4)); CK(cudaMalloc(&s2a,n*4*4));
  CK(cudaMalloc(&s1b,n*4*4)); CK(cudaMalloc(&s2b,n*4*4));
  CK(cudaMemcpy(d_coeffs,h_coeffs,n*4,cudaMemcpyHostToDevice));
  CK(cudaMemcpy(d_fac,h_fac,log_n*4*4,cudaMemcpyHostToDevice));
  uint32_t rh[4],rf[4];
  if(run(false,d_coeffs,h_fac,d_fac,n,s1a,s2a,rh)) return 2;
  if(run(true ,d_coeffs,h_fac,d_fac,n,s1b,s2b,rf)) return 2;
  printf("hand  = %u %u %u %u\n",rh[0],rh[1],rh[2],rh[3]);
  printf("forge = %u %u %u %u\n",rf[0],rf[1],rf[2],rf[3]);
  bool eq = rh[0]==rf[0]&&rh[1]==rf[1]&&rh[2]==rf[2]&&rh[3]==rf[3];
  printf(eq?"*** MATCH — forge eval byte-identical to hand kernel ***\n":"*** MISMATCH ***\n");
  return eq?0:1;
}
