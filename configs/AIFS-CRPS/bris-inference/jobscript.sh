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
#SBATCH --job-name=infer
#SBATCH --output=logs/aifs-crps.out
# #SBATCH --error=logs/aifs-crps.err

set -euxo pipefail

export HYDRA_FULL_ERROR=1

module purge
module load gcc/12.2.0
module load cuda/12.2
module load hpcx-mpi

unset VIRTUAL_ENV

#export PATH=/leonardo_work/DestE_330_25/users/asalihi0/compiled-libraries/python/python-3.11.7-gcc-12.2.0-cmake-3.27.9/bin:$PATH
#export LD_LIBRARY_PATH=/leonardo_work/DestE_330_25/users/asalihi0/compiled-libraries/python/python-3.11.7-gcc-12.2.0-cmake-3.27.9/lib:$LD_LIBRARY_PATH
#export SQLITE_DIR=/leonardo_work/DestE_330_25/users/asalihi0/compiled-libraries/python/sqlite-3.45-gcc-12.2.0
#export LD_LIBRARY_PATH=$SQLITE_DIR/lib:$LD_LIBRARY_PATH

#uv sync --locked

srun uv run --locked bris --config=aifs-crps.yaml
