# bris-configs

`bris-configs` collects experiment and runtime configuration for Bris and
Anemoi-based workflows on Leonardo. It contains project-specific setups for
training, Bris inference, and direct `anemoi-inference` runs, including the
YAML configs, `uv` environments, and Slurm jobs needed to reproduce them.

## Layout

- `configs/<project>/anemoi-training`: training configs and job scripts
- `configs/<project>/bris-inference`: Bris runtime configs and environments
- `configs/<project>/anemoi-inference`: direct checkpoint inference setups

Each project directory is intended to be runnable on its own, with local
`README.md`, `pyproject.toml`, `uv.lock`, and `jobscript.sh` files where
needed.
