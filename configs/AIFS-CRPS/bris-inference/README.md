# AIFS-CRPS bris-inference

This directory is a `uv` project for running the AIFS-CRPS Bris-inference job.

## Files

- `pyproject.toml`: project definition
- `uv.lock`: locked dependency set
- `.venv/`: local virtual environment managed by `uv`
- `config.yaml`: BRIS runtime configuration
- `jobscript.sh`: Slurm submission script
- `aifs-ens-crps-1.0.ckpt`: checkpoint used by `config.yaml`

## Setup

Run these commands from this directory:

```bash
uv sync
```

This creates or updates `.venv` from `pyproject.toml` and `uv.lock`.

If you change dependencies, refresh the lock and sync again:

```bash
uv lock
uv sync
```

## Running locally

Run from this directory:

```bash
uv run bris --config=config.yaml
```

To force the exact lockfile environment:

```bash
uv run --locked bris --config=config.yaml
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

- change into this directory
- create `logs/` if needed
- load the required compiler, CUDA, and MPI modules
- export the Python and SQLite library paths used by this setup
- run `uv sync --locked`
- launch `bris` with `srun uv run --locked bris --config=config.yaml`

## Notes

- The project is pinned to Python `3.11.13`.
- `bris` is installed from `git@github.com:metno/bris-inference.git` at the revision recorded in `pyproject.toml` and `uv.lock`.
- Adding `bris` changed some package versions relative to the original `freeze.txt`, and `uv.lock` now reflects the actual runnable environment.
