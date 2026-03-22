# boiling-blizzard training

This folder contains the files needed to retrain the boiling-blizzard checkpoint in four stages.

## Files

- `freeze.txt`: package snapshot used to reconstruct the training environment
- `pyproject.toml`: uv project definition
- `uv.lock`: uv lockfile
- `.venv/`: local uv environment
- `jobscript.sh`: Slurm jobscript that runs from this directory
- `boiling-blizzard_r1.yaml`
- `boiling-blizzard_r2.yaml`
- `boiling-blizzard_r3-6.yaml`
- `boiling-blizzard_r6_ifs.yaml`

## Setup

Run from this directory:

```bash
uv sync
```

This folder is now a `uv` project. The environment is described by `pyproject.toml` and `uv.lock`, and `uv sync` will create or update `.venv`.

## Running locally

After syncing the environment, run:

```bash
uv run anemoi-training train --config-name=boiling-blizzard_r1.yaml
```

Swap the config name for the stage you want to run.

## Training order

Run the configs in this order:

1. `boiling-blizzard_r1.yaml`
2. `boiling-blizzard_r2.yaml`
3. `boiling-blizzard_r3-6.yaml`
4. `boiling-blizzard_r6_ifs.yaml`

## Running with Slurm

Submit from this directory:

```bash
sbatch jobscript.sh
```

The script will:

- change into this directory
- create `logs/` if needed
- sync or reuse `.venv`
- launch `uv run anemoi-training train --config-name=boiling-blizzard_r1.yaml`

Update `jobscript.sh` for each stage by changing:

- `#SBATCH --job-name`
- `#SBATCH --output`
- `--config-name=...`

## Notes

- The environment was reconstructed literally from `freeze.txt` to match the old training setup as closely as possible.
- The freeze file includes a few pinned combinations that are not resolver-clean, so rebuilding it exactly requires the same literal install approach used to create the current `.venv`.
