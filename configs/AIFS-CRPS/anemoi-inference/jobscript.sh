#!/bin/bash

#SBATCH -A EUHPC_R06_263
#SBATCH -p boost_usr_prod
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=0
#SBATCH --time=24:00:00
#SBATCH --job-name=aifs-anemoi-infer
#SBATCH --output=logs/%x-%j.out
#SBATCH --array=1-10

set -euxo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$(pwd)}"
cd "$SCRIPT_DIR"
mkdir -p logs
mkdir -p netcdf

module purge
module load gcc/12.2.0
module load cuda/12.2
module load hpcx-mpi
export CUDA_HOME="${CUDA_HOME:-$(dirname "$(dirname "$(which nvcc)")")}"
export MAX_JOBS="${MAX_JOBS:-4}"

unset VIRTUAL_ENV

VENV_DIR="$SCRIPT_DIR/.venv"
SITE_PACKAGES="$VENV_DIR/lib64/python3.11/site-packages"

# Torch 2.5.0 pulls CUDA 12.4 user-space libraries from PyPI. Prepend those
# vendored libraries so they are used ahead of the older CUDA 12.2 module libs.
if [[ -d "$SITE_PACKAGES/nvidia" ]]; then
  NVIDIA_LIB_DIRS=(
    "$SITE_PACKAGES/nvidia/nvjitlink/lib"
    "$SITE_PACKAGES/nvidia/cublas/lib"
    "$SITE_PACKAGES/nvidia/cuda_cupti/lib"
    "$SITE_PACKAGES/nvidia/cuda_nvrtc/lib"
    "$SITE_PACKAGES/nvidia/cuda_runtime/lib"
    "$SITE_PACKAGES/nvidia/cudnn/lib"
    "$SITE_PACKAGES/nvidia/cufft/lib"
    "$SITE_PACKAGES/nvidia/curand/lib"
    "$SITE_PACKAGES/nvidia/cusolver/lib"
    "$SITE_PACKAGES/nvidia/cusparse/lib"
    "$SITE_PACKAGES/nvidia/nccl/lib"
    "$SITE_PACKAGES/nvidia/nvtx/lib"
  )

  for lib_dir in "${NVIDIA_LIB_DIRS[@]}"; do
    if [[ -d "$lib_dir" ]]; then
      export LD_LIBRARY_PATH="$lib_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
  done
fi

uv sync

if ! "$VENV_DIR/bin/python" -c "import flash_attn" >/dev/null 2>&1; then
  UV_PROJECT_ENVIRONMENT="$VENV_DIR" uv pip install     --python "$VENV_DIR/bin/python"     --no-build-isolation     "flash-attn==2.7.4.post1"
fi

START_DATE="${START_DATE:-2024-01-01T00:00:00}"
LEAD_TIME="${LEAD_TIME:-120h}"
RUN_ID="${RUN_ID:-${SLURM_ARRAY_TASK_ID:-single}}"
OUTPUT_PATH="${OUTPUT_PATH:-./netcdf/aifs-ens-crps-1.0-${RUN_ID}.nc}"

srun uv run --locked anemoi-inference run   aifs-ens-crps-1.0.yaml   "date=${START_DATE}"   "lead_time=${LEAD_TIME}"   "output.netcdf.path=${OUTPUT_PATH}"
