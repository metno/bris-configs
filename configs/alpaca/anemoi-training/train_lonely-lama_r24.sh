#!/bin/bash
# =============================================================================
# train_lonely-lama_r24.sh — gradual rollout fine-tuning of lonely-lama (lonely-lama_r24.yaml): MEPS 2.5 km
# cutout + n320, 2 epochs at rollout 2, 1 at rollout 3, 1 at rollout 4 (~1536 steps, ~4 h), 16 nodes.
#
#   sbatch train_lonely-lama_r24.sh
#   RUN_ID=<run id> sbatch --dependency=afterany:<jobid> train_lonely-lama_r24.sh     # requeue if cut by the walltime
#   EXTRA="key=value ..." appends hydra overrides; sbatch flags override the #SBATCH headers.
# =============================================================================
#SBATCH --job-name=lonely_lama_r24
#SBATCH --account=EUHPC_R06_263                 # e.g. EUHPC_R06_263
#SBATCH --partition=boost_usr_prod
##SBATCH --qos=boost_qos_dbg
#SBATCH --nodes=16
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --mem=0
#SBATCH --exclusive
#SBATCH --time=12:00:00
#SBATCH --output=/leonardo_work/EUHPC_R06_263/hhaugen/alpaca/logs/%x_%j.out      # e.g. <ROOT>/logs/%x_%j.out (directory must exist)

set -euo pipefail

ROOT=/leonardo_scratch/fast/EUHPC_R06_263/hhaugen/alpaca     # project root (same BASE as in setup_env_torch28_shared.sh)
VENV=${VENV:-${ROOT}/venvs/anemoi-torch28}
CFGDIR=/leonardo_work/EUHPC_R06_263/hhaugen/alpaca/bris-configs/configs/alpaca/anemoi-training
CONFIG=${CONFIG:-lonely-lama_r24.yaml}
RUN_ID=${RUN_ID:-}                     # set on requeue segments: anemoi resumes from last.ckpt of that run

module purge
module load python/3.11.7
source "${VENV}/bin/activate"

export OMP_NUM_THREADS=1
export PYTHONUNBUFFERED=1
export HYDRA_FULL_ERROR=1
export TORCH_NCCL_ASYNC_ERROR_HANDLING=1
export NCCL_IB_TIMEOUT=22
export SLURM_GPUS_PER_NODE=${SLURM_GPUS_PER_NODE:-4}
export MLFLOW_ALLOW_FILE_STORE=true    # offline mlflow file store (newer mlflow gates it behind this)
# Do NOT set PYTORCH_CUDA_ALLOC_CONF=expandable_segments: incompatible with the compiled blocks.

HYDRA_DIR=${ROOT}/logs/hydra/${CONFIG}_${SLURM_JOB_ID}
mkdir -p "${HYDRA_DIR}" && cd "${HYDRA_DIR}"
echo "== $(date) CONFIG=${CONFIG} nodes=${SLURM_NNODES} gpus/node=${SLURM_GPUS_PER_NODE} anemoi-core $(git -C ${ROOT}/src/anemoi-core rev-parse --short HEAD)"

srun --cpu-bind=cores \
  anemoi-training train \
    --config-path="${CFGDIR}" \
    --config-name="${CONFIG}" \
    hydra.run.dir="${HYDRA_DIR}" \
    ${RUN_ID:+training.run_id=${RUN_ID}} \
    ${EXTRA:-}
echo "== $(date) done"
