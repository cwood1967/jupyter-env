#!/bin/bash
set -euo pipefail

GIT_SOURCE="https://github.com/cwood1967/jupyter-env.git"
TARGET_DIR="$HOME/Desktop/jupyter-env"

if ! command -v uv >/dev/null 2>&1; then
  echo "uv not found - installing..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
if ! command -v uv >/dev/null 2>&1; then
  echo "Failed to install uv. Install it manually from https://astral.sh/uv, then re-run this file."
  read -n 1 -s -r -p "Press any key to exit..."
  exit 1
fi

echo "$TARGET_DIR"
echo "Now checking for uv"
if [ -d "$TARGET_DIR/.git" ]; then
  echo "Updating existing env..."
  git -C "$TARGET_DIR" fetch origin && git -C "$TARGET_DIR" reset --hard origin/main
else
  if [ -d "$TARGET_DIR" ]; then
    echo "Removing incomplete install from $TARGET_DIR"
    rm -rf "$TARGET_DIR"
  fi
  echo "Cloning"
  git clone "$GIT_SOURCE" "$TARGET_DIR"
fi

cd "$TARGET_DIR"
# The cpu extra resolves to the PyPI (arm64/MPS) build on macOS; there is no
# CUDA variant here. --no-sync keeps uv run from re-syncing without the extra.
uv sync --extra cpu
uv run --no-sync napari
