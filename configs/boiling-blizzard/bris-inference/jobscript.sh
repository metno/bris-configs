#!/bin/bash

#SBATCH -A EUHPC_R06_263
#SBATCH -p boost_usr_prod
#SBATCH -q boost_qos_dbg
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=4
#SBATCH --mem=0
#SBATCH --time=00:30:00
#SBATCH --job-name=boiling-blizzard
#SBATCH --output=logs/boiling-blizzard.out

set -euxo pipefail

export HYDRA_FULL_ERROR=1

# Recreate/update the local project environment from uv.lock before launching.
uv sync --locked

srun uv run --locked bris --config=boiling-blizzard.yaml
