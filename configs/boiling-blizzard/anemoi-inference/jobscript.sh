#!/bin/bash

#SBATCH -A EUHPC_R06_263
#SBATCH -p boost_usr_prod
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=0
#SBATCH --time=06:00:00
#SBATCH --job-name=boiling-blizzard-anemoi-infer
#SBATCH --output=logs/%x-%j.out
#SBATCH --array=0-1  # specify the number of members here

set -euxo pipefail

uv sync --locked

START_DATE="${START_DATE:-2024-12-01T00:00:00}"
LEAD_TIME="${LEAD_TIME:-240h}"
RUN_ID="${RUN_ID:-${SLURM_ARRAY_TASK_ID:-single}}"
OUTPUT_PATH="${OUTPUT_PATH:-./netcdf/boiling-blizzard-${RUN_ID}.nc}"

srun uv run --locked anemoi-inference run boiling-blizzard.yaml "date=${START_DATE}" "lead_time=${LEAD_TIME}" "output.netcdf.path=${OUTPUT_PATH}"
