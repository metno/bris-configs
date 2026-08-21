#!/bin/bash
# ============================================================================
# setup_env_torch28_shared.sh — shared Leonardo environment for o96 pre-training:
# torch 2.8.0+cu126 + pyg-lib, enabling block-level torch.compile
# (+45% samples/s/node at o96/1024c vs uncompiled).
#
# RUN ON A LOGIN NODE. Fill in the TODOs first.
#
# Key pins and why:
#   torch==2.8.0+cu126   - first torch where anemoi's block compile works (2.6 crashes
#                          activation checkpointing). Pinned via a constraints file on EVERY
#                          pip call: the anemoi editable install otherwise re-resolves torch
#                          to the newest release and breaks the PyG-wheel ABI
#                          (libpyg.so undefined symbol).
#   pyg-lib + cluster/sparse/scatter from the torch-2.8.0+cu126 wheel index.
#   anemoi-core          - editable checkout pinned to release training-0.16.0 (c3c7a893f).
#
# Usage notes for runs on this env:
#   * model.compile: transformer blocks + ConditionalLayerNorm only — NEVER add a
#     CRPS/loss (max-autotune) entry: it crashes validation on torch 2.6 AND 2.8.
#   * Do NOT set PYTORCH_CUDA_ALLOC_CONF=expandable_segments (incompatible with compile).
#   * Export MLFLOW_ALLOW_FILE_STORE=true in jobscripts for offline mlflow logging.
# ============================================================================
set -euo pipefail

BASE=TODO                 # your project area, e.g. /leonardo_scratch/fast/<ACCOUNT>/$USER/<project>
VENV=${BASE}/venvs/anemoi-torch28
SRC=${BASE}/src/anemoi-core   # clone of anemoi-core, checked out at training-0.16.0 (c3c7a893f):
                              #   git clone https://github.com/ecmwf/anemoi-core "$SRC"
                              #   git -C "$SRC" checkout c3c7a893f
C=$(mktemp); echo "torch==2.8.0" > "$C"

module purge
module load python/3.11.7
python -m venv "${VENV}"
source "${VENV}/bin/activate"
pip install --upgrade pip wheel setuptools
pip install torch==2.8.0 --index-url https://download.pytorch.org/whl/cu126
pip install -c "$C" pyg-lib torch-cluster torch-sparse torch-scatter \
    -f https://data.pyg.org/whl/torch-2.8.0+cu126.html
pip install -c "$C" torch_geometric
pip install -c "$C" -e "${SRC}/training[plotting]" \
                    -e "${SRC}/models[spectral]" \
                    -e "${SRC}/graphs[tri]"
pip freeze > "${VENV}/requirements-torch28.lock.$(date +%Y%m%d)"

python - << 'PY'
import torch, torch_geometric, pyg_lib  # noqa: F401
assert torch.__version__.startswith("2.8"), torch.__version__
print("torch", torch.__version__, "| PyG", torch_geometric.__version__, "| pyg-lib OK")
import anemoi.training, anemoi.models, anemoi.graphs  # noqa: F401
print("anemoi import OK")
PY
echo "Env ready:  source ${VENV}/bin/activate"
