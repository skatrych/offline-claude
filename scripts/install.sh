#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SRC="$SCRIPT_DIR/offline-claude"
TARGET_DIR="$HOME/bin"
TARGET="$TARGET_DIR/offline-claude"

if [[ ! -f "$SRC" ]]; then
  echo "Error: source script not found: $SRC" >&2
  exit 2
fi

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Error: target directory does not exist: $TARGET_DIR" >&2
  echo "Please create $TARGET_DIR and ensure it's on your PATH, then re-run this script." >&2
  exit 2
fi

ln -sf "$SRC" "$TARGET"
chmod +x "$SRC"

echo "Installed symlink: $TARGET -> $SRC"
