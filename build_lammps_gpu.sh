#!/bin/bash
# build_lammps_gpus.sh
#
# Build LAMMPS on Isambard‑AI with:
#   MPI + Kokkos(CUDA), NO OpenMP
#
# IMPORTANT:
#   Run this script from the LAMMPS source root directory:
#     lammps/
#       cmake/
#       src/
#       lib/kokkos/bin/nvcc_wrapper
#
# Usage:
#   cd /path/to/lammps
#   chmod +x build_lammps_gpus.sh
#   ./build_lammps_gpus.sh

set -euo pipefail

# Silence Lmod warnings/info
module() { command module "$@" 2>/dev/null; }

BUILD_DIR_NAME="build-kokkos-cuda-mpi"
JOBS=${JOBS:-8}

LAMMPS_ROOT="$(pwd)"

if [[ ! -d "${LAMMPS_ROOT}/cmake" || ! -x "${LAMMPS_ROOT}/lib/kokkos/bin/nvcc_wrapper" ]]; then
  echo "ERROR: Run this script from the LAMMPS source root directory." >&2
  exit 1
fi

echo "Building LAMMPS in ${LAMMPS_ROOT}"

module purge
module load craype/2.7.34
module load craype-network-ofi
module load PrgEnv-gnu/8.6.0
module load cray-mpich/8.1.32
module load libfabric/1.22.0
module load cray-fftw/3.3.10.10
module load cuda/12.6
module load cpe-cuda/25.03

export NVCCWRAP="${LAMMPS_ROOT}/lib/kokkos/bin/nvcc_wrapper"
export NVCC_WRAPPER_DEFAULT_COMPILER=CC
export CRAYPE_LINK_TYPE=dynamic

make -C "${LAMMPS_ROOT}/src" no-all purge >/dev/null 2>&1 || true

BUILD_DIR="${LAMMPS_ROOT}/${BUILD_DIR_NAME}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cmake "${LAMMPS_ROOT}/cmake" \
  -D CMAKE_C_COMPILER=cc \
  -D CMAKE_CXX_COMPILER="${NVCCWRAP}" \
  -D CMAKE_Fortran_COMPILER=ftn \
  -D BUILD_MPI=on \
  -D PKG_KOKKOS=on \
  -D Kokkos_ENABLE_CUDA=on \
  -D Kokkos_ENABLE_OPENMP=off \
  -D Kokkos_ARCH_HOPPER90=ON \
  -D PKG_KSPACE=on \
  -D PKG_MISC=on \
  -D PKG_MC=on \
  -D PKG_EXTRA-MOLECULE=on \
  -D FFT=FFTW3 \
  -D CMAKE_BUILD_TYPE=Release

cmake --build . -j "${JOBS}"

echo "Build complete: ${BUILD_DIR}/lmp"
