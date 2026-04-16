# boiling-blizzard anemoi-inference

This directory contains a standalone `uv` project for running the
`boiling-blizzard` checkpoint with `anemoi-inference`.

## Files

- `pyproject.toml`: project definition
- `uv.lock`: locked dependency set
- `.venv/`: local virtual environment managed by `uv`
- `boiling-blizzard.yaml`: runnable `anemoi-inference` config
- `jobscript.sh`: Slurm submission script
- `subset_netcdf.py`: helper to keep the boiling-blizzard variable list in NetCDF outputs

## Setup

Run these commands from this directory:

```bash
uv lock
uv sync
```

## Assumptions

- The checkpoint path comes from `configs/boiling-blizzard/bris-inference/boiling-blizzard.yaml`:
  `/leonardo_work/DestE_330_25/anemoi/experiments/ens/checkpoint/ad153dc196f847199a4f6b4a14aa69e1/inference-last.ckpt`.
- The dataset path and selected variable list are copied from
  `configs/boiling-blizzard/bris-inference/boiling-blizzard.yaml`.
- The BRIS config uses `leadtimes: 84` with a `6h` timestep, so this config defaults to `lead_time: 504h`.
- This checkpoint does not require `flash-attn`, so the environment and jobscript stay minimal.

## Running locally

Run from this directory:

```bash
uv run anemoi-inference run boiling-blizzard.yaml
```

You can override key settings on the command line, for example:

```bash
uv run anemoi-inference run   boiling-blizzard.yaml   date=2024-01-01T00:00:00   lead_time=120h   output.netcdf.path=./netcdf/boiling-blizzard-test.nc
```

## Running with Slurm

Submit from this directory:

```bash
sbatch jobscript.sh
```

The script will:

- create `logs/` and `netcdf/` if needed
- load the required compiler, CUDA, and MPI modules
- prepend the vendored NVIDIA libraries from `.venv` to `LD_LIBRARY_PATH`
- run `uv sync --locked`
- run `anemoi-inference` with `START_DATE`, `LEAD_TIME`, and `OUTPUT_PATH` overrides

You can override those submission-time settings like this:

```bash
sbatch --export=ALL,START_DATE=2024-01-01T00:00:00,LEAD_TIME=120h,RUN_ID=test1 jobscript.sh
```

## Subsetting NetCDF outputs

To keep only the boiling-blizzard variable list from `bris-inference`, run:

```bash
uv run python subset_netcdf.py
```

By default the script keeps whatever requested variables are present and reports any missing ones.
Use `--require-all` if you want it to fail instead.
