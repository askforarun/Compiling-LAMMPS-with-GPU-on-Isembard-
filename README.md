# Compiling-LAMMPS-with-GPU-on-Isembard-

Here are the steps 

module purge
module load brics/default brics/userenv
module load PrgEnv-gnu
module load craype-network-ofi
module load gcc-native/13.2
module load cuda/12.6

export CRAYPE_LINK_TYPE=dynamic



g++ --version     # should show GCC 13.2.x
nvcc --version    # CUDA 12.6


export NVCC_WRAPPER_DEFAULT_COMPILER=$(which g++)


cd /scratch/<your_username>/lammps-22Jul2025
rm -rf build-kokkos-gpu
mkdir build-kokkos-gpu
cd build-kokkos-gpu


cmake ../cmake \
  -D CMAKE_C_COMPILER=cc \
  -D CMAKE_CXX_COMPILER=../lib/kokkos/bin/nvcc_wrapper \
  -D CMAKE_Fortran_COMPILER=ftn \
  -D BUILD_MPI=on \
  -D PKG_KOKKOS=on \
  -D Kokkos_ENABLE_CUDA=on \
  -D Kokkos_ENABLE_OPENMP=on \
  -D Kokkos_ARCH_HOPPER90=ON \
  -D CMAKE_BUILD_TYPE=Release

if Hopper isn't recognized use the following (Hopper is the codename for NVIDIA’s H100 GPU architecture, also known as SM_90 or compute capability 9.0.)
-D Kokkos_ARCH_AMPERE80=ON

Finally type 
cmake --build . -j 16

./lmp
