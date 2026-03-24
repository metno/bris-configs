# cozy-cirrus anemoi-training

This directory is a `uv` project for running the `cozy-cirrus` training job.

## Files

- `pyproject.toml`: project definition
- `uv.lock`: locked dependency set
- `.venv/`: local virtual environment managed by `uv`
- `cozy-cirrus.yaml`: training config
- `jobscript.sh`: Slurm submission script
- `freeze.txt`: original package snapshot used as reference for reconstructing the environment

## Setup

From this directory:

```bash
uv lock
uv sync
```

## Running locally

```bash
uv run anemoi-training train --config-name=cozy-cirrus.yaml
```

## Running with Slurm

```bash
sbatch jobscript.sh
```

The script will:

- change into this directory
- create `logs/` if needed
- run `uv sync --locked`
- launch `uv run --locked anemoi-training train --config-name=cozy-cirrus.yaml`
