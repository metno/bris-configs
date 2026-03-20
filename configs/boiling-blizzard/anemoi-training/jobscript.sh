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
#SBATCH --job-name=boiling-blizzard_r1
#SBATCH --output=logs/boiling-blizzard_r1_1.out

set -euxo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"
mkdir -p logs

export HYDRA_FULL_ERROR=1
unset VIRTUAL_ENV
source .venv/bin/activate

# Update --config-name and the Slurm job/output names for each stage.
srun anemoi-training train --config-name=boiling-blizzard_r1.yaml
