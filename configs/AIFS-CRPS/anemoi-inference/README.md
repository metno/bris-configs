# AIFS-CRPS anemoi-inference

This directory contains a standalone `uv` project for running the
`aifs-ens-crps-1.0.ckpt` checkpoint with `anemoi-inference`.

## Files

- `pyproject.toml`: project definition
- `uv.lock`: locked dependency set
- `.venv/`: local virtual environment managed by `uv`
- `aifs-ens-crps-1.0.ckpt`: checkpoint
- `aifs-ens-crps-1.0.yaml`: runnable `anemoi-inference` config
- `jobscript.sh`: Slurm submission script

## Setup

Run these commands from this directory:

```bash
uv lock
uv sync
```

The environment expects `flash-attn==2.7.4.post1`, which is required to load
this checkpoint.

## Assumptions

- The config uses the merged AIFS dataset at
  `/leonardo_work/DestE_340_25/ai-ml/datasets/aifs-od-an-oper-0001-mars-n320-2016-2025-6h-v1-for-single-v2.zarr`.
- The checkpoint metadata reports a `6h` timestep and two lagged input times.
- Output defaults to `./aifs-ens-crps-1.0.nc` relative to the working directory.

## Running locally

Run from this directory:

```bash
uv run anemoi-inference run aifs-ens-crps-1.0.yaml
```

You can override key settings on the command line, for example:

```bash
uv run anemoi-inference run \
  aifs-ens-crps-1.0.yaml \
  date=2024-01-01T00:00:00 \
  lead_time=24h \
  output.netcdf.path=./aifs-ens-crps-1.0-20240101T00.nc
```

If you need the same module stack as the Slurm job, load it before running:

```bash
module purge
module load gcc/12.2.0
module load cuda/12.2
module load hpcx-mpi
```

## Running with Slurm

Submit from this directory:

```bash
sbatch jobscript.sh
```

The script will:

- create `logs/` if needed
- load the required compiler, CUDA, and MPI modules
- prepend the vendored NVIDIA libraries from `.venv` to `LD_LIBRARY_PATH`
- run `uv sync`
- install `flash-attn==2.7.4.post1` into `.venv` if it is missing
- run `anemoi-inference` with `START_DATE`, `LEAD_TIME`, and `OUTPUT_PATH` overrides

You can override those submission-time settings like this:

```bash
sbatch --export=ALL,START_DATE=2024-01-01T00:00:00,LEAD_TIME=24h,OUTPUT_PATH=./aifs-20240101T00.nc jobscript.sh
```
