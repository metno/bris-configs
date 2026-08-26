# Alpaca O96 training

This folder contains the files needed to train O96 test models for Bris3.0

Contents:
- `basic-alpaca.yaml` — hydra base config (fill in the `TODO`s: graph path, output root,
  run id, mlflow run name). Speed levers included and verified on Leonardo boost nodes:
  block-level `model.compile` (+45%), `num_chunks: 1` (+6.5%), bf16 gradient-compression DDP
  hook (+30% at 8 nodes), `drop_last: True`, geometry 2 members x 1 GPU per group,
  bs2 @ 4 nodes (~35% cheaper than 8 nodes x bs1 at identical effective batch/LR).
  Graph: encoder KNN 12 + edge_length norm unit-max (stretched_grid conventions), otherwise the
  packaged multi_scale graph (TriNodes 5, KNN-3 decoder).
- `small-alpaca.yaml` - example for base config overwrite
- `training/scalers/pretrain.yaml` — loss-scaler group (full replacement; no tendency scalers).
- `build_graph.py` — single-process CPU graph pre-builder (required before the first run).
- `anemoi-core-drop_last.patch` — 6-line datamodule patch (applied by the setup script) that makes
  the config's `dataloader.drop_last: True` effective; without it the key is silently ignored.
  We will probably end up with a fork with the fix (and other features) in eventually,
  so this may be removed later.
- `setup_env_torch28_shared.sh` — full setup from ONE variable (`BASE`): folder layout, the moving
  `alpaca` branch from the metno anemoi-core fork, venv (torch 2.8.0+cu126 + pyg-lib).
- `train_o96.sh` — 24 h training segment (4 nodes x bs2); TODOs: job name, account, log path, ROOT;
  `CONFIG=<name>` selects the config, `RUN_ID=<id>` requeues a segment.

**Build the graph once before the first training job** (anemoi builds it on every rank with no
coordination and the KNN edge builder hangs on non-zero local ranks — see build_graph.py docstring):
```
python build_graph.py --config-dir <this folder> --config base_o96_pretrain --out <your graph path>
```
(set `system.input.graph` to the same path; keep that one file canonical for the project.)

Run:
```
anemoi-training train --config-path=<this folder> --config-name=base_o96_pretrain
```
(use `--config-path`, NOT `--config-dir` — the latter has lowest priority and lets packaged
group files shadow these).

Submit: `CONFIG=base_o96_pretrain sbatch train_o96.sh` (then `RUN_ID=<id> ... --dependency=afterany:<jobid>`
for the second segment: 200k steps @ 4 nodes x bs2 ≈ 27 h; or 8 nodes x bs1 with `lr: 6.25e-5` ≈ 19 h).
