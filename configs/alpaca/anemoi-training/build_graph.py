#!/usr/bin/env python
"""Pre-build the training graph for a config on CPU (login node, seconds), single process.

Why: anemoi-training builds the graph on EVERY rank with no coordination, and the KNN edge builder's
pyg/CUDA path hangs on ranks whose local device is not cuda:0 (first build of the KNN-12 graph,
smoke 53311524: 1/4 ranks finished). With the file present, every rank simply loads it.
Replicates AnemoiTrainer.graph_data's config expansion (train.py) and calls GraphCreator.

Usage:  venvs/anemoi-torch28-202608/bin/python jobs/build_graph.py --config e0_knn [--out <path>] [--overwrite]
        (default --out = the config's system.input.graph)
"""
import argparse, os, sys
os.environ.setdefault("SLURM_NNODES", "1"); os.environ.setdefault("SLURM_GPUS_ON_NODE", "4")
from hydra import compose, initialize_config_dir
from omegaconf import OmegaConf, DictConfig

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", required=True)
    ap.add_argument("--config-dir", default=os.path.join(ROOT, "configs"))
    ap.add_argument("--out", default=None)
    ap.add_argument("--overwrite", action="store_true")
    args = ap.parse_args()
    with initialize_config_dir(version_base=None, config_dir=os.path.abspath(args.config_dir)):
        cfg = compose(config_name=args.config)
    out = args.out or cfg.system.input.graph
    if os.path.exists(out) and not args.overwrite:
        sys.exit(f"{out} exists (use --overwrite to rebuild)")

    from anemoi.graphs.create import GraphCreator
    from anemoi.training.schemas.dataloader import DatasetConfigSchema  # same filter as train.py

    graph_config = OmegaConf.create(OmegaConf.to_container(cfg.graph, resolve=True))
    reader_cfg = cfg.dataloader.training.datasets.data.dataset_config
    dataset_path = OmegaConf.to_container(reader_cfg["dataset"], resolve=True) if isinstance(reader_cfg["dataset"], DictConfig) else reader_cfg["dataset"]
    graph_dataset_value = {"dataset": dataset_path}
    schema_keys = set(DatasetConfigSchema.model_fields.keys())
    graph_dataset_value.update({k: v for k, v in OmegaConf.to_container(reader_cfg, resolve=True).items()
                                if k not in schema_keys and v is not None})
    graph_config.nodes.data.node_builder.dataset = graph_dataset_value
    graph = GraphCreator(graph_config).create(save_path=out, overwrite=args.overwrite)
    print(f"saved {out}")
    for et in graph.edge_types:
        print(f"  {et}: {graph[et].edge_index.shape[1]} edges")

if __name__ == "__main__":
    main()
