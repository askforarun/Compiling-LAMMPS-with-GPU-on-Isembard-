#!/bin/bash
set -e

# Build script for LAMMPS GPU compilation on Isambard

module load cray-fftw

make -C src no-all purge

rm -rf build
mkdir build
cd build

cmake ../cmake   -D CMAKE_C_COMPILER=cc   -D CMAKE_CXX_COMPILER=$NVCCWRAP   -D CMAKE_Fortran_COMPILER=ftn   -D BUILD_MPI=on   -D PKG_KOKKOS=on   -D Kokkos_ENABLE_CUDA=on   -D Kokkos_ENABLE_OPENMP=on   -D Kokkos_ARCH_HOPPER90=ON   -D PKG_KSPACE=on   -D PKG_MISC=on   -D PKG_MC=on   -D PKG_EXTRA-MOLECULE=on   -D FFT=FFTW3   -D CMAKE_BUILD_TYPE=Release

cmake --build . -j
