#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="/home/claude/workspace"
STATE_DIR="/home/claude/.claude"
OLLAMA_MODELS_URL="http://ollama-proxy:11434/v1/models"

fail() {
  echo "[pre-flight] ERROR: $1" >&2
  exit 1
}

check_dir_writable() {
  local dir="$1"
  local label="$2"

  [[ -d "$dir" ]] || fail "$label directory does not exist: $dir"
  [[ -w "$dir" ]] || fail "$label directory is not writable: $dir"
}

check_dir_writable "$WORKSPACE_DIR" "Workspace"
check_dir_writable "$STATE_DIR" "State"

if ! curl --silent --show-error --fail "$OLLAMA_MODELS_URL" >/dev/null; then
  fail "Ollama proxy is not reachable or /v1/models did not return success: $OLLAMA_MODELS_URL"
fi

if curl --silent --max-time 5 https://google.com >/dev/null 2>&1; then
  fail "Internet egress is reachable from claude container (https://google.com). Isolation is broken."
fi

echo "[pre-flight] OK: workspace/state writable, Ollama proxy reachable, internet egress blocked"
