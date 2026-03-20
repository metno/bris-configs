#!/bin/bash

#SBATCH -A AIFAC_5C0_154 #DestE_340_26 #EUHPC_R04_079
#SBATCH -p boost_usr_prod
#SBATCH -q boost_qos_dbg
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=4
#SBATCH --gpus-per-node=4
#SBATCH --cpus-per-task=4
#SBATCH --mem=0
#SBATCH --time=00:30:00
#SBATCH --job-name=boiling-blizzard
#SBATCH --output=logs/infer_verif.out
# #SBATCH --dependency=afterany:35529068

set -euxo pipefail

#SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#cd "${SCRIPT_DIR}"

export HYDRA_FULL_ERROR=1

# Recreate/update the local project environment from uv.lock before launching.
uv sync --locked

srun uv run --locked bris --config=config.yaml
