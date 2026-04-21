#!/bin/bash

#SBATCH -A EUHPC_R06_263
#SBATCH -p boost_usr_prod
# #SBATCH -q boost_qos_dbg
#SBATCH --nodes=40
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=4
#SBATCH --mem=0
#SBATCH --time=20:00:00
#SBATCH --job-name=calm-coriolis
#SBATCH --output=logs/calm-coriolis.out
#SBATCH --dependency=afterany:40103335

set -euxo pipefail

export HYDRA_FULL_ERROR=1

# Recreate/update the local project environment from uv.lock before launching.
uv sync --locked

srun uv run --locked bris --config=config_verif.yaml
