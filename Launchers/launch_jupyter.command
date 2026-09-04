#!/bin/bash
set -euo pipefail

GIT_SOURCE="https://github.com/cwood1967/jupyter-env.git" # or "napari[all]" + --with-requirements for Option B
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

NB_DIR="${1:-}"
if [ -z "$NB_DIR" ]; then
  # Host the picker in whatever app is already frontmost (i.e. the Terminal that
  # launched this script). osascript itself is faceless, so a panel it owns has a
  # dead sidebar; and telling Finder to activate loses a race - the modal panel
  # appears before Finder is frontmost, so macOS just bounces the Dock icon
  # instead of giving it focus. The frontmost app needs no activation at all.
  #
  # Read the script into a variable first: macOS ships bash 3.2 as /bin/bash, and
  # 3.2 mis-parses a here-document nested inside $( ) - it scans for the closing
  # paren without skipping the heredoc body, so an apostrophe in the AppleScript
  # looks like an unterminated quote. Keep the heredoc outside the substitution.
  read -r -d '' PICKER_SCRIPT <<'APPLESCRIPT' || true
try
    set frontApp to (path to frontmost application) as text
    tell application frontApp
        set chosenFolder to choose folder with prompt "Choose a folder to open in Jupyter" default location (path to home folder)
    end tell
on error errMsg number errNum
    -- -128 is the user clicking Cancel; re-raise it so we do not ask twice.
    if errNum is -128 then error number -128
    tell application "Finder"
        activate
        set chosenFolder to choose folder with prompt "Choose a folder to open in Jupyter" default location (path to home folder)
    end tell
end try
return POSIX path of chosenFolder
APPLESCRIPT

  NB_DIR=$(osascript -e "$PICKER_SCRIPT" 2>/dev/null) || {
    echo "No folder selected"
    read -n 1 -s -r -p "Press any key to exit"
    exit 1
  }
fi

if [ -z "$NB_DIR" ]; then
  echo "No folder selected"
  read -n 1 -s -r -p "Press any key to exit"
  exit 1
fi

echo "${NB_DIR}"
cd "$TARGET_DIR"
# The cpu extra resolves to the PyPI (arm64/MPS) build on macOS; there is no
# CUDA variant here. --no-sync keeps uv run from re-syncing without the extra.
echo "Installing the environment"
uv sync --extra cpu
echo "Launching jupyter"
uv run --no-sync jupyter lab --notebook-dir="$NB_DIR"
