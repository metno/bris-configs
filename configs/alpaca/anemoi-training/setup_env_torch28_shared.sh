#!/bin/bash
# ============================================================================
# setup_env_torch28_shared.sh — shared Leonardo environment for o96 pre-training:
# torch 2.8.0+cu126 + pyg-lib, enabling block-level torch.compile
# (+45% samples/s/node at o96/1024c vs uncompiled).
#
# RUN ON A LOGIN NODE. Set BASE (the only TODO): the script creates the folder layout
# (src/ venvs/ configs/ graphs/ logs/), clones anemoi-core's alpaca branch, and builds the venv.
# Afterwards: copy this folder's configs into ${BASE}/configs and the jobscript into ${BASE}/.
#
# Key pins and why:
#   torch==2.8.0+cu126   - first torch where anemoi's block compile works (2.6 crashes
#                          activation checkpointing). Pinned via a constraints file on EVERY
#                          pip call: the anemoi editable install otherwise re-resolves torch
#                          to the newest release and breaks the PyG-wheel ABI
#                          (libpyg.so undefined symbol).
#   pyg-lib + cluster/sparse/scatter from the torch-2.8.0+cu126 wheel index.
#   anemoi-core          - editable checkout of the metno fork's moving alpaca branch.
#
# Usage notes for runs on this env:
#   * model.compile: transformer blocks + ConditionalLayerNorm only — NEVER add a
#     CRPS/loss (max-autotune) entry: it crashes validation on torch 2.6 AND 2.8.
#   * Do NOT set PYTORCH_CUDA_ALLOC_CONF=expandable_segments (incompatible with compile).
#   * Export MLFLOW_ALLOW_FILE_STORE=true in jobscripts for offline mlflow logging.
# ============================================================================
set -euo pipefail

BASE=TODO     # the ONLY thing to set: your project root, e.g. /leonardo_scratch/fast/<ACCOUNT>/$USER/<project>
VENV=${BASE}/venvs/anemoi-torch28
SRC=${BASE}/src/anemoi-core
SRC_INFER=${BASE}/src/bris-inference
C=$(mktemp); echo "torch==2.8.0" > "$C"

# --- folder layout + anemoi-core fork clone ----------------------------------------------------
mkdir -p "${BASE}"/{src,venvs,configs,graphs,logs/hydra}
if [ ! -d "${SRC}/.git" ]; then
  git clone https://github.com/metno/anemoi-core "${SRC}"
fi
if [ ! -d "${SRC_INFER}/.git" ]; then
  git clone https://github.com/metno/bris-inference "${SRC_INFER}"
fi
git -C "${SRC}" checkout alpaca
# The fork publishes no package tags, so give setuptools-scm the release versions
# on which alpaca is based. Otherwise it generates 0.0.0.postN versions that fail
# the packages' internal dependency constraints.
export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_ANEMOI_TRAINING=0.16.0
export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_ANEMOI_MODELS=0.18.0
export SETUPTOOLS_SCM_PRETEND_VERSION_FOR_ANEMOI_GRAPHS=0.9.6
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
pip install -c "$C" gridpp==0.8.0.dev3
pip install -c "$C" -e "${SRC_INFER}" --no-deps
pip freeze > "${VENV}/requirements-torch28.lock.$(date +%Y%m%d)"

python - << 'PY'
import torch, torch_geometric, pyg_lib  # noqa: F401
assert torch.__version__.startswith("2.8"), torch.__version__
print("torch", torch.__version__, "| PyG", torch_geometric.__version__, "| pyg-lib OK")
import anemoi.training, anemoi.models, anemoi.graphs  # noqa: F401
print("anemoi import OK")
PY
echo "Env ready:  source ${VENV}/bin/activate"
