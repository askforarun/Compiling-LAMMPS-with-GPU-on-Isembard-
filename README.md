# Compiling LAMMPS with GPU (Kokkos + CUDA) and MPI on Isambard‑AI

This guide explains how to **compile LAMMPS with GPU support using Kokkos + CUDA and MPI**
on **Isambard‑AI**.  
The build is **MPI‑only on the host** (no OpenMP).

> This README intentionally **does not include any Slurm job scripts**.  
> It focuses only on building LAMMPS.

---

## Summary of the build

- MPI: **Cray MPICH**
- GPU backend: **Kokkos + CUDA**
- Host parallelism: **MPI only (OpenMP disabled)**
- FFT: **cray‑fftw**
- Target GPU: **NVIDIA GH200 / Hopper**

---

## 1. Prerequisites

- Access to **Isambard‑AI**
- A clean LAMMPS source tree cloned from GitHub

```bash
git clone https://github.com/lammps/lammps.git
cd lammps
```

All commands below assume you are **inside the LAMMPS source root directory**:

```
lammps/
 ├── cmake/
 ├── src/
 └── lib/kokkos/bin/nvcc_wrapper
```

---

## 2. Module environment (warning‑free)

On Isambard, `PrgEnv-gnu` can emit a harmless Lmod warning.
To keep logs clean, we silence module stderr **inside the build script**.

The build script loads:

- `craype`
- `craype-network-ofi`
- `PrgEnv-gnu`
- `cray-mpich`
- `cuda`
- `cpe-cuda`
- `cray-fftw`

You do **not** need to load modules manually if you use the provided script.

---

## 3. Build script (recommended)

This repository provides a fully automated build script:

```
build_lammps_gpus.sh
```

### What the script does

- Verifies it is run from the LAMMPS source root
- Loads the correct Isambard‑AI modules
- Uses Cray MPI compiler wrappers (`cc`, `CC`, `ftn`)
- Enables:
  - MPI
  - Kokkos
  - CUDA
- Disables:
  - OpenMP
- Builds LAMMPS using CMake (out‑of‑source build)

---

## 4. How to build

From the **LAMMPS source root directory**:

```bash
chmod +x build_lammps_gpus.sh
./build_lammps_gpus.sh
```

The build directory created is:

```
build-kokkos-cuda-mpi/
```

The resulting executable will be:

```
build-kokkos-cuda-mpi/lmp
```

---

## 5. Verify the build

After compilation:

```bash
./build-kokkos-cuda-mpi/lmp -h | grep -A8 "Accelerator configuration"
```

You should see:

- KOKKOS enabled
- CUDA enabled
- MPI enabled (Cray MPICH)
- No OpenMP requirement

You can also check MPI explicitly:

```bash
./build-kokkos-cuda-mpi/lmp -h | grep MPI
```

---

## 6. Notes

- This build is suitable for **GPU‑accelerated LAMMPS runs using MPI ranks**.
- OpenMP is intentionally disabled to avoid Kokkos OpenMP warnings and to keep
  the execution model simple and robust.
- Runtime GPU/CPU configuration is handled entirely at job‑submission time.

---

## 7. Files provided

- `README.md` – this document
- `build_lammps_gpus.sh` – automated build script for Isambard‑AI

You are now ready to run GPU‑accelerated LAMMPS jobs using MPI.
