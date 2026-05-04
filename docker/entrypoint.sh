#!/usr/bin/env bash
set -euo pipefail

: "${CLAUDE_MODEL:?CLAUDE_MODEL must be set}"

/usr/local/bin/pre-flight-check.sh

echo "[entrypoint] Starting Claude Code"
echo "[entrypoint] Model: ${CLAUDE_MODEL}"
echo "[entrypoint] Base URL: ${ANTHROPIC_BASE_URL:-unset}"
echo "[entrypoint] Workspace: $(pwd)"

exec claude --model "${CLAUDE_MODEL}" "$@"
