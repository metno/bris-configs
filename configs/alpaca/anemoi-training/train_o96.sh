#!/bin/bash
# =============================================================================
# train_o96.sbatch — o96 ensemble pre-training, one 24 h segment (Leonardo boost, 4 nodes x bs2).
#
#   CONFIG=base_o96_pretrain sbatch train_o96.sbatch                              # first segment
#   CONFIG=base_o96_pretrain RUN_ID=<run id> sbatch --dependency=afterany:<jobid> train_o96.sbatch   # requeue
#   (command-line sbatch flags override the #SBATCH headers: --nodes, --time, --qos, --job-name ...)
#
# Before the first segment: build the graph once -> python build_graph.py --config-dir <cfgdir> ...
# 200k steps @ 4 nodes x bs2 ~ 27 h -> plan one requeue segment (RUN_ID = the first segment's run id,
# printed in its log / the checkpoint directory name). EXTRA="key=value ..." appends hydra overrides.
# =============================================================================
#SBATCH --job-name=TODO                # e.g. o96_pretrain
#SBATCH --account=TODO                 # e.g. EUHPC_R06_263
#SBATCH --partition=boost_usr_prod
#SBATCH --qos=normal
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --mem=0
#SBATCH --exclusive
#SBATCH --time=24:00:00
#SBATCH --output=TODO/%x_%j.out        # e.g. <ROOT>/logs/%x_%j.out (directory must exist)

set -euo pipefail

ROOT=TODO                              # project root (same BASE as in setup_env_torch28_shared.sh)
VENV=${VENV:-${ROOT}/venvs/anemoi-torch28}
CFGDIR=${CFGDIR:-${ROOT}/configs}      # folder holding base_o96_pretrain.yaml + training/scalers/
CONFIG=${CONFIG:?set CONFIG=<config name without .yaml>}
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
