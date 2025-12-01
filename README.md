# Building LAMMPS (KOKKOS + CUDA) on Isambard-AI (H100 GPU Nodes)

This guide explains how to compile **LAMMPS 22Jul2025** with **GPU acceleration (KOKKOS + CUDA)** on **Isambard-AI** GPU nodes.  
Isambard-AI uses **NVIDIA H100 (Hopper, SM_90)** GPUs.

The build uses the **KOKKOS** backend (recommended by LAMMPS for modern GPUs).

---

# 1. Start a GPU Interactive Session

```bash
srun -N 1 --gpus 1 --time=01:00:00 --pty bash
```

---

# 2. Load Required Modules

```bash
module purge
module load brics/default brics/userenv
module load PrgEnv-gnu
module load craype-network-ofi
module load gcc-native/13.2
module load cuda/12.6

export CRAYPE_LINK_TYPE=dynamic
```

### Check compilers:

```bash
g++ --version     # should show GCC 13.x
nvcc --version    # should show CUDA 12.6
```

### Tell Kokkos which compiler to use:

```bash
export NVCC_WRAPPER_DEFAULT_COMPILER=$(which g++)
```

---

# 3. Prepare a Clean Build Directory

```bash
cd /scratch/u5ec/ass2009.u5ec/lammps-22Jul2025
rm -rf build-kokkos-gpu
mkdir build-kokkos-gpu
cd build-kokkos-gpu
```

---

# 4. Use an Absolute Path to nvcc_wrapper

```bash
NVCCWRAP=$(cd .. && pwd)/lib/kokkos/bin/nvcc_wrapper
echo $NVCCWRAP
```

Expected output:

```
/scratch/u5ec/ass2009.u5ec/lammps-22Jul2025/lib/kokkos/bin/nvcc_wrapper
```

---

# 5. Configure LAMMPS (KOKKOS + CUDA for H100 / Hopper)

```bash
cmake ../cmake   -D CMAKE_C_COMPILER=cc   -D CMAKE_CXX_COMPILER=$NVCCWRAP   -D CMAKE_Fortran_COMPILER=ftn   -D BUILD_MPI=on   -D PKG_KOKKOS=on   -D Kokkos_ENABLE_CUDA=on   -D Kokkos_ENABLE_OPENMP=on   -D Kokkos_ARCH_HOPPER90=ON   -D CMAKE_BUILD_TYPE=Release
```

### If Hopper is not recognised:

```bash
-D Kokkos_ARCH_AMPERE80=ON
```

---

# 6. Build LAMMPS

```bash
cmake --build . -j 16
```

Executable appears as:

```bash
./lmp
```

---

# 7. Optional: Quick GPU Test

```bash
srun -N 1 --gpus 1 ./lmp   -sf kk   -pk kokkos neigh half gpu/host   -in ../examples/KOKKOS/in.lj
```

---

# 8. Example SLURM Script for Production Runs

Create: `run_lammps_gpu.slurm`

```bash
#!/bin/bash
#SBATCH --job-name=lammps_gpu
#SBATCH --nodes=1
#SBATCH --gpus-per-node=1
#SBATCH --time=02:00:00
#SBATCH --account=<your_project>

module purge
module load brics/default brics/userenv
module load PrgEnv-gnu
module load craype-network-ofi
module load gcc-native/13.2
module load cuda/12.6

export CRAYPE_LINK_TYPE=dynamic
export NVCC_WRAPPER_DEFAULT_COMPILER=$(which g++)

cd /scratch/<your_username>/lammps-22Jul2025/build-kokkos-gpu

srun ./lmp -sf kk -pk kokkos neigh half gpu/host -in /path/to/input.in
```

Submit job:

```bash
sbatch run_lammps_gpu.slurm
```

---

# 9. Summary

- Targets **NVIDIA H100 (Hopper)** via `Kokkos_ARCH_HOPPER90=ON`  
- Uses recommended **KOKKOS** backend  
- Requires **gcc-native/13.2**  
- Uses an absolute path for `nvcc_wrapper` to avoid CMake errors  
