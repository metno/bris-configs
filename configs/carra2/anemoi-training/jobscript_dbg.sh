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
#SBATCH --job-name=carra2
#SBATCH --output=logs/carra2_benchmark.out
#SBATCH --dependency=singleton
set -x

export HYDRA_FULL_ERROR=1
export MLFLOW_ALLOW_FILE_STORE=true

source /leonardo_work/EUHPC_R06_263/enordhag/venvs/carra2/bin/activate

srun anemoi-training train --config-name=config_carra2_latest_anemoi.yaml
