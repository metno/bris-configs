#!/bin/bash

#SBATCH -A AIFAC_5C0_154
#SBATCH -p boost_usr_prod
#SBATCH -q boost_qos_dbg
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=4
#SBATCH --mem=0
#SBATCH --time=00:30:00
#SBATCH --job-name=cozy-cirrus
#SBATCH --output=logs/cozy-cirrus_1.out
#SBATCH --dependency=singleton

set -euxo pipefail

export HYDRA_FULL_ERROR=1
unset VIRTUAL_ENV
uv sync --locked

srun uv run --locked anemoi-training train --config-name=cozy-cirrus.yaml
