#!/bin/bash
# build_lammps_gpu.sh
#
# Step-by-step build helper for Isambard-AI:
#   LAMMPS + MPI (Cray MPICH) + Kokkos(CUDA) and NO OpenMP
#
# IMPORTANT: Run this script from the LAMMPS source root directory
# (the directory that contains: cmake/ src/ lib/kokkos/bin/nvcc_wrapper)
#
# Usage:
#   cd /scratch/u5ec/ass2009.u5ec/lammps-22Jul2025
#   chmod +x build_lammps_gpu.sh
#   ./build_lammps_gpu.sh
#
# Optional:
#   JOBS=16 ./build_lammps_gpu.sh

set -euo pipefail

BUILD_DIR="build-kokkos-cuda-mpi"
JOBS="${JOBS:-8}"

echo "========================================"
echo "LAMMPS build (Isambard-AI): MPI + CUDA (Kokkos), no OpenMP"
echo "PWD      : $(pwd)"
echo "BUILD_DIR: ${BUILD_DIR}"
echo "JOBS     : ${JOBS}"
echo "========================================"

# ---- Check we are in LAMMPS root ----
if [[ ! -d "cmake" || ! -d "src" || ! -e "lib/kokkos/bin/nvcc_wrapper" ]]; then
  echo "ERROR: Run this script from the LAMMPS source root directory." >&2
  echo "Expected to find: cmake/ src/ lib/kokkos/bin/nvcc_wrapper" >&2
  exit 2
fi

LAMMPS_ROOT="$(pwd)"
NVCCWRAP="${LAMMPS_ROOT}/lib/kokkos/bin/nvcc_wrapper"

# ---- Load modules ----
# Some sites emit a harmless Lmod warning when loading PrgEnv-gnu.
# To keep logs clean, we silence module stderr.
module() { command module "$@" 2>/dev/null; }

module purge
module load craype/2.7.34
module load craype-network-ofi
module load PrgEnv-gnu/8.6.0
module load cray-mpich/8.1.32
module load libfabric/1.22.0
module load cray-fftw/3.3.10.10
module load cuda/12.6
module load cpe-cuda/25.03

echo "Loaded modules:"
command module list 2>&1 || true
echo

# ---- Ensure nvcc_wrapper is executable ----
if [[ ! -x "${NVCCWRAP}" ]]; then
  chmod +x "${NVCCWRAP}" || true
fi

# ---- Critical: nvcc host compiler must be GCC <= 13 ----
# On Isambard-AI, PrgEnv-gnu may pin GCC 14; nvcc 12.6 rejects GCC > 13.
# Fix: point nvcc_wrapper at a GCC 13 g++.
#
# You MUST edit GCC13_GPP below to match your system if it differs.
GCC13_GPP_DEFAULT="/opt/cray/pe/gcc-native/13.2/bin/g++"
GCC13_GPP="${GCC13_GPP:-${GCC13_GPP_DEFAULT}}"

if [[ ! -x "${GCC13_GPP}" ]]; then
  echo "ERROR: GCC13 g++ not found at: ${GCC13_GPP}" >&2
  echo "Set GCC13_GPP to your GCC 13 g++ path, e.g.:" >&2
  echo "  GCC13_GPP=$(which -a g++ | head -n 5 | tail -n 1) ./build_lammps_gpu.sh" >&2
  echo "Or find candidates with:" >&2
  echo "  which -a g++ | head -10" >&2
  exit 3
fi

export NVCCWRAP
export NVCC_WRAPPER_DEFAULT_COMPILER="${GCC13_GPP}"
export CRAYPE_LINK_TYPE=dynamic

echo "Using nvcc_wrapper  : ${NVCCWRAP}"
echo "nvcc host compiler  : ${NVCC_WRAPPER_DEFAULT_COMPILER}"
echo

# ---- Clean old build dir ----
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# ---- Optional cleanup of legacy make artifacts ----
make -C "${LAMMPS_ROOT}/src" no-all purge >/dev/null 2>&1 || true

# ---- Configure ----
cmake ../cmake \
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

# ---- Build ----
cmake --build . -j "${JOBS}"

echo
echo "========================================"
echo "Build complete:"
echo "  ${LAMMPS_ROOT}/${BUILD_DIR}/lmp"
echo "Verify:"
echo "  ${LAMMPS_ROOT}/${BUILD_DIR}/lmp -h | grep -A8 'Accelerator configuration'"
echo "========================================"
