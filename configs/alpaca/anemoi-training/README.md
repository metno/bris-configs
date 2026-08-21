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
- `training/scalers/pretrain.yaml` — loss-scaler group (full replacement; no tendency scalers).
- `build_graph.py` — single-process CPU graph pre-builder (required before the first run).
- `setup_env_torch28_shared.sh` — environment build (torch 2.8.0+cu126 + pyg-lib +
  anemoi-core @ training-0.16.0). Fill in `BASE`, clone anemoi-core as noted inside.

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

Jobscript essentials: `--ntasks-per-node=4 --gpus-per-node=4`, `MLFLOW_ALLOW_FILE_STORE=true`,
no `expandable_segments` allocator. 200k steps @ 4 nodes x bs2 ≈ 27 h → plan one resume segment
(set `training.run_id` to the first segment's run id), or 8 nodes x bs1 with `lr: 6.25e-5` ≈ 19 h.
