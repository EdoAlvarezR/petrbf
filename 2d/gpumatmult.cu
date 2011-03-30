const int threadsPerBlock = 128;

unsigned int hostOffsetSize;
unsigned int hostTargetSize;
unsigned int hostSourceSize;

static unsigned int is_set=0;
static unsigned int deviceOffsetSize;
static unsigned int deviceTargetSize;
static unsigned int deviceSourceSize;

static int   *deviceOffset;
static float *deviceTargetX;
static float *deviceTargetY;
static float *deviceTargetW;
static float *deviceSourceX;
static float *deviceSourceY;
static float *deviceSourceG;

__global__ void kernel(int* deviceOffset, float* deviceTargetX, float* deviceTargetY, float* deviceTargetW,
                       float sigma,       float* deviceSourceX, float* deviceSourceY, float* deviceSourceG)
{
  int i = blockIdx.x * threadsPerBlock + threadIdx.x;
  int jbase,jsize,jblok,j,jb,jj;
  float targetX,targetY,targetW,dx,dy,coef;
  __shared__ float sharedSourceX[threadsPerBlock];
  __shared__ float sharedSourceY[threadsPerBlock];
  __shared__ float sharedSourceG[threadsPerBlock];

  targetX = deviceTargetX[i];
  targetY = deviceTargetY[i];
  targetW = 0;
  coef = 0.5f/(sigma*sigma);
  jbase = deviceOffset[blockIdx.x];
  jsize = deviceOffset[blockIdx.x+1]-deviceOffset[blockIdx.x];
  jblok = (jsize + threadsPerBlock - 1) / threadsPerBlock;
  for (j = 0; j < jblok-1; j++) {
    jb = jbase + j * threadsPerBlock + threadIdx.x;
    __syncthreads();
    sharedSourceX[threadIdx.x] = deviceSourceX[jb];
    sharedSourceY[threadIdx.x] = deviceSourceY[jb];
    sharedSourceG[threadIdx.x] = deviceSourceG[jb];
    __syncthreads();
#pragma unroll 32
    for(jj = 0; jj < threadsPerBlock; jj++){
      dx = targetX-sharedSourceX[jj];
      dy = targetY-sharedSourceY[jj];
      targetW += sharedSourceG[jj]*exp(-(dx*dx+dy*dy)*coef);
    }
  }
  jb = jbase + j * threadsPerBlock + threadIdx.x;
  __syncthreads();
  sharedSourceX[threadIdx.x] = deviceSourceX[jb];
  sharedSourceY[threadIdx.x] = deviceSourceY[jb];
  sharedSourceG[threadIdx.x] = deviceSourceG[jb];
  __syncthreads();
  for(jj = 0; jj < jsize - (j * threadsPerBlock); jj++){
    dx = targetX-sharedSourceX[jj];
    dy = targetY-sharedSourceY[jj];
    targetW += sharedSourceG[jj]*exp(-(dx*dx+dy*dy)*coef);
  }
  deviceTargetW[i] = targetW/M_PI*coef;
}

void gpumatmult(float *hostTargetX, float *hostTargetY, float *hostTargetW,
                float *hostSourceX, float *hostSourceY, float *hostSourceG,
                int *hostOffset, int iblok, float sigma, int numCluster, int numTrunc)
{
  hostOffsetSize = sizeof(int) * (numCluster+1);
  hostTargetSize = sizeof(float) * numCluster * threadsPerBlock;
  hostSourceSize = sizeof(float) * numCluster * numTrunc;

  if (is_set==0) {
    cudaSetDevice(0);
    is_set=1;
  }
  if (hostOffsetSize>deviceOffsetSize) {
    if(deviceOffsetSize!=0) cudaFree(deviceOffset);
    cudaMalloc((void**)&deviceOffset,hostOffsetSize);
    deviceOffsetSize=hostOffsetSize;
  }
  if (hostTargetSize>deviceTargetSize) {
    if(deviceTargetSize!=0) {
      cudaFree(deviceTargetX);
      cudaFree(deviceTargetY);
      cudaFree(deviceTargetW);
    }
    cudaMalloc((void**)&deviceTargetX,hostTargetSize);
    cudaMalloc((void**)&deviceTargetY,hostTargetSize);
    cudaMalloc((void**)&deviceTargetW,hostTargetSize);
    deviceTargetSize=hostTargetSize;
  }
  if (hostSourceSize>deviceSourceSize) {
    if(deviceSourceSize!=0) {
      cudaFree(deviceSourceX);
      cudaFree(deviceSourceY);
      cudaFree(deviceSourceG);
    }
    cudaMalloc((void**)&deviceSourceX,hostSourceSize);
    cudaMalloc((void**)&deviceSourceY,hostSourceSize);
    cudaMalloc((void**)&deviceSourceG,hostSourceSize);
    deviceSourceSize=hostSourceSize;
  }

  cudaMemcpy(deviceOffset,hostOffset,hostOffsetSize,cudaMemcpyHostToDevice);
  cudaMemcpy(deviceTargetX,hostTargetX,hostTargetSize,cudaMemcpyHostToDevice);
  cudaMemcpy(deviceTargetY,hostTargetY,hostTargetSize,cudaMemcpyHostToDevice);
  cudaMemcpy(deviceSourceX,hostSourceX,hostSourceSize,cudaMemcpyHostToDevice);
  cudaMemcpy(deviceSourceY,hostSourceY,hostSourceSize,cudaMemcpyHostToDevice);
  cudaMemcpy(deviceSourceG,hostSourceG,hostSourceSize,cudaMemcpyHostToDevice);

  dim3 block(threadsPerBlock);
  dim3 grid(iblok);
  kernel<<< grid, block >>>(deviceOffset,deviceTargetX,deviceTargetY,deviceTargetW,
                                   sigma,deviceSourceX,deviceSourceY,deviceSourceG);

  cudaMemcpy(hostTargetW,deviceTargetW,hostTargetSize,cudaMemcpyDeviceToHost);

}
