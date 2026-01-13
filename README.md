# Compiling LAMMPS with GPU (Kokkos + CUDA) and MPI on Isambard-AI

This guide documents a **working, reproducible procedure** to compile **LAMMPS**
with:

- MPI (Cray MPICH)
- GPU acceleration via **Kokkos + CUDA**
- OpenMP disabled (MPI-only on host)
- Target: **NVIDIA GH200 / Hopper (Isambard-AI)**

This README is intentionally **step-by-step**, without scripts or Slurm files.

---

## 1. Prerequisites

- Access to **Isambard-AI**
- CUDA-capable login/build environment
- LAMMPS source code (July 22, 2025 or compatible)

Clone LAMMPS:

```bash
git clone https://github.com/lammps/lammps.git
cd lammps
```

You **must** be in the **LAMMPS source root**, which should contain:

```text
cmake/
src/
lib/kokkos/bin/nvcc_wrapper
```

---

## 2. Load required modules (Isambard-AI)

Run these **exactly in this order**:

```bash
module purge
module load craype/2.7.34
module load craype-network-ofi
module load PrgEnv-gnu/8.6.0
module load cray-mpich/8.1.32
module load libfabric/1.22.0
module load cray-fftw/3.3.10.10
module load cuda/12.6
module load cpe-cuda/25.03
```

You may see an Lmod warning about `cray-mpich` and network targeting.
This warning is **harmless** and does **not** affect the build.

---

## 3. Compiler sanity check

Ensure the Cray compiler wrappers exist:

```bash
which cc
which CC
which ftn
which nvcc
```

All commands must return valid paths.

---

## 4. CUDA vs GCC version issue (critical)

CUDA 12.6 does **not** support GCC 14 as a host compiler.
On Isambard-AI, `PrgEnv-gnu` may force GCC 14.

The solution is to explicitly tell **nvcc_wrapper** which compiler to use.

From the **LAMMPS source root**:

```bash
export NVCCWRAP=$PWD/lib/kokkos/bin/nvcc_wrapper
export CRAYPE_LINK_TYPE=dynamic
```

Find a **GCC 13** compiler path:

```bash
which -a g++ | head -10
```

Identify the **GCC 13.x** path and set:

```bash
export NVCC_WRAPPER_DEFAULT_COMPILER=/path/to/g++-13
```

Example:

```bash
export NVCC_WRAPPER_DEFAULT_COMPILER=/opt/cray/pe/gcc-native/13.2/bin/g++
```

---

## 5. Clean old builds (recommended)

```bash
make -C src no-all purge || true
```

---

## 6. Create a fresh build directory

```bash
rm -rf build-kokkos-cuda-mpi
mkdir build-kokkos-cuda-mpi
cd build-kokkos-cuda-mpi
```

---

## 7. Configure LAMMPS with CMake (MPI + CUDA, no OpenMP)

```bash
cmake ../cmake   -D CMAKE_C_COMPILER=cc   -D CMAKE_CXX_COMPILER=$NVCCWRAP   -D CMAKE_Fortran_COMPILER=ftn   -D BUILD_MPI=on   -D PKG_KOKKOS=on   -D Kokkos_ENABLE_CUDA=on   -D Kokkos_ENABLE_OPENMP=off   -D Kokkos_ARCH_HOPPER90=ON   -D PKG_KSPACE=on   -D PKG_MISC=on   -D PKG_MC=on   -D PKG_EXTRA-MOLECULE=on   -D FFT=FFTW3   -D CMAKE_BUILD_TYPE=Release
```

Successful configuration ends with:

```text
Build files have been written to: .../build-kokkos-cuda-mpi
```

---

## 8. Build LAMMPS

```bash
cmake --build . -j 8
```

The binary will be:

```bash
build-kokkos-cuda-mpi/lmp
```

---

## 9. Verify the build

```bash
./lmp -h | grep -A8 "Accelerator configuration"
./lmp -h | grep -A5 "MPI v"
```

You should see KOKKOS, CUDA, and MPI enabled.

---

## 10. Notes

- Optimised for **MPI + GPU**
- Avoid legacy `package gpu` commands
- Use Kokkos at runtime with:
  ```bash
  -k on g 1 -sf kk
  ```

---

## 11. Status

Tested and working on **Isambard-AI (GH200)**.
