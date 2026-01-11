# Compiling LAMMPS with GPU (Kokkos + CUDA) on Isambard

This repository documents a **reproducible, CMake-based workflow** for compiling **LAMMPS with GPU support** on **Isambard (Cray/HPE system)** using:

- MPI (Cray wrappers)
- Kokkos + CUDA
- OpenMP
- FFTW (via `cray-fftw`)
- Additional LAMMPS packages (KSPACE, MISC, MC, EXTRA-MOLECULE, etc.)

⚠️ **Important**: This guide assumes you are using the **CMake build system only**.  
Mixing CMake with the legacy make-based build system (`make yes-*`) will cause build failures.

---

## System assumptions

- Isambard / Cray programming environment
- NVIDIA GPUs (H100 / Hopper)
- Cray compiler wrappers available:
  - `cc` (C)
  - `ftn` (Fortran)
  - `nvcc_wrapper` (C++ via `$NVCCWRAP`)
- LAMMPS source tree cloned locally

---

## 1️⃣ Clone LAMMPS

```bash
git clone https://github.com/lammps/lammps.git
cd lammps
```

---

## 2️⃣ **MANDATORY**: Clean legacy make-based build artifacts

```bash
make -C src no-all purge
```

---

## 3️⃣ Load required modules (Isambard)

```bash
module load cray-fftw
```

---

## 4️⃣ Create a clean out-of-source build directory

```bash
rm -rf build
mkdir build
cd build
```

---

## 5️⃣ Full CMake configuration (GPU + additional packages)

```bash
cmake ../cmake \
  -D CMAKE_C_COMPILER=cc \
  -D CMAKE_CXX_COMPILER=$NVCCWRAP \
  -D CMAKE_Fortran_COMPILER=ftn \
  -D BUILD_MPI=on \
  -D PKG_KOKKOS=on \
  -D Kokkos_ENABLE_CUDA=on \
  -D Kokkos_ENABLE_OPENMP=on \
  -D Kokkos_ARCH_HOPPER90=ON \
  -D PKG_KSPACE=on \
  -D PKG_MISC=on \
  -D PKG_MC=on \
  -D PKG_EXTRA-MOLECULE=on \
  -D FFT=FFTW3 \
  -D CMAKE_BUILD_TYPE=Release
```

---

## 6️⃣ Build LAMMPS

```bash
cmake --build . -j
```

---

## 7️⃣ Verify enabled packages

```bash
./lmp -h | grep -A5 "Installed packages"
```

---

## 8️⃣ Automated build using a bash script

See `build_lammps_gpu.sh` in this repository.

```bash
chmod +x build_lammps_gpu.sh
./build_lammps_gpu.sh
```

---

## 9️⃣ Example SLURM script for production GPU runs

Save as `run_lammps_gpu.slurm`:

```bash
#!/bin/bash
#SBATCH --job-name=lmp_gpu
#SBATCH --account=<YOUR_ACCOUNT>
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --gpus=1
#SBATCH --time=24:00:00
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err

set -euo pipefail

module purge
module load cray-fftw

LAMMPS_EXE="$SLURM_SUBMIT_DIR/build/lmp"
INPUT="$SLURM_SUBMIT_DIR/in.lammps"

export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OMP_PROC_BIND=spread
export OMP_PLACES=cores

srun --mpi=pmix \
  "${LAMMPS_EXE}" \
  -in "${INPUT}" \
  -k on g 1 \
  -sf kk \
  -pk kokkos newton on neigh full comm device \
  -pk kokkos omp ${OMP_NUM_THREADS}
```

Submit the job:
```bash
sbatch run_lammps_gpu.slurm
```

---

## ❌ Common mistakes

- Mixing make-based and CMake-based builds
- Forgetting `make -C src no-all purge`
- Building inside `src/`
- Enabling KSPACE without FFTW

---

## ✅ Summary

This workflow is:

- ✔ CMake-clean  
- ✔ GPU-ready (Kokkos + CUDA)  
- ✔ Cray/Isambard compatible  
- ✔ Safe for adding new LAMMPS packages  
- ✔ Suitable for production GPU runs  
