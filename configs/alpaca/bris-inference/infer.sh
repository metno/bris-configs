#!/bin/bash
# =============================================================================
#
# =============================================================================
#SBATCH --job-name=YOUR_JOB_NAME
#SBATCH --account=EUHPC_R06_263
#SBATCH --partition=boost_usr_prod
##SBATCH --qos=boost_qos_dbg
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --mem=0
#SBATCH --exclusive
#SBATCH --time=00:20:00
#SBATCH --output=/YOUR_LOGS_FOLDER/%x_%j.out

set -euo pipefail
CFG=YOUR_CONFIG_PATH
VENV=YOUR_VENV_PATH

module purge
module load python/3.11.7
# PATH sanitiser (2026-08-23): an unsearchable directory on PATH (e.g. an expired project dir from the
# login profile) makes Python's subprocess raise PermissionError for ANY missing executable, which turns
# torch.compile's optional `nvcc --version` probe into a fatal InductorError. Drop such entries.
export PATH=$(echo "$PATH" | tr ':' '\n' | while read -r d; do [ -n "$d" ] && [ -x "$d" ] && echo "$d"; done | paste -sd:)
source "${VENV}/bin/activate"
export OMP_NUM_THREADS=1 PYTHONUNBUFFERED=1
export SLURM_GPUS_PER_NODE=${SLURM_GPUS_PER_NODE:-4}

srun --cpu-bind=cores bris --config "${CFG}"
