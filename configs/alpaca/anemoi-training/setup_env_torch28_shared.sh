#!/bin/bash
# ============================================================================
# setup_env_torch28_shared.sh — shared Leonardo environment for o96 pre-training:
# torch 2.8.0+cu126 + pyg-lib, enabling block-level torch.compile
# (+45% samples/s/node at o96/1024c vs uncompiled).
#
# RUN ON A LOGIN NODE. Set BASE (the only TODO): the script creates the folder layout
# (src/ venvs/ configs/ graphs/ logs/), clones anemoi-core at the pinned commit, and builds the venv.
# Afterwards: copy this folder's configs into ${BASE}/configs and the jobscript into ${BASE}/.
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

BASE=TODO                 # the ONLY thing to set: your project root, e.g. /leonardo_scratch/fast/<ACCOUNT>/$USER/<project>
ANEMOI_COMMIT=c3c7a893f   # anemoi-core release training-0.16.0 / models-0.18.0 / graphs-0.9.6
VENV=${BASE}/venvs/anemoi-torch28
SRC=${BASE}/src/anemoi-core
C=$(mktemp); echo "torch==2.8.0" > "$C"

# --- folder layout + pinned anemoi-core clone --------------------------------------------------
mkdir -p "${BASE}"/{src,venvs,configs,graphs,logs/hydra}
if [ ! -d "${SRC}/.git" ]; then
  git clone https://github.com/ecmwf/anemoi-core "${SRC}"
fi
git -C "${SRC}" fetch --tags
git -C "${SRC}" checkout "${ANEMOI_COMMIT}"
echo "anemoi-core at $(git -C "${SRC}" rev-parse --short HEAD)"
# drop_last support for the dataloader (6-line local patch, upstream-PR candidate): a partial final
# batch would force a recompilation of the compiled blocks and crash torch 2.8's AOT autograd.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if git -C "${SRC}" apply --check "${HERE}/anemoi-core-drop_last.patch" 2>/dev/null; then
  git -C "${SRC}" apply "${HERE}/anemoi-core-drop_last.patch" && echo "applied anemoi-core-drop_last.patch"
else
  echo "anemoi-core-drop_last.patch already applied or not applicable — check manually"
fi

module purge
module load python/3.11.7
python -m venv "${VENV}"
source "${VENV}/bin/activate"
pip install --upgrade pip wheel setuptools
pip install torch==2.8.0 --index-url https://download.pytorch.org/whl/cu126
pip install -c "$C" pyg-lib torch-cluster torch-sparse torch-scatter \
    -f https://data.pyg.org/whl/torch-2.8.0+cu126.html
pip install -c "$C" torch_geometric
pip install -c "$C" anemoi-datasets==0.5.34
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
