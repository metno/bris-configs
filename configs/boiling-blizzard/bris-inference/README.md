# boiling-blizzard bris-inference

This directory is a `uv` project for running the `boiling-blizzard` Bris inference job.

## Files

- `pyproject.toml`: project definition
- `uv.lock`: locked dependency set
- `.venv/`: local virtual environment managed by `uv`
- `config.yaml`: BRIS runtime configuration
- `jobscript.sh`: Slurm submission script

## Setup

From this directory:

```bash
uv sync
```

This creates or updates `.venv` from `pyproject.toml` and `uv.lock`.

If you want to refresh the lock file after dependency changes:

```bash
uv lock
uv sync
```

## Running locally

From this directory:

```bash
uv run bris --config=config.yaml
```

If you want to ensure the exact locked environment is used:

```bash
uv run --locked bris --config=config.yaml
```

## Running with Slurm

Submit the bundled jobscript from this directory:

```bash
sbatch jobscript.sh
```

The script will:

- change into the project directory
- create `logs/` if needed
- run `uv sync --locked`
- launch `bris` with `srun uv run --locked bris --config=config.yaml`

## Notes

- The project is pinned to Python `3.12.11`.
- `bris` is installed from `git@github.com:metno/bris-inference.git` at the revision recorded in `pyproject.toml` and `uv.lock`.
- PyTorch CUDA 12.4 packages are resolved via the configured `uv` index in `pyproject.toml`.
