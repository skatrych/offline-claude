# Usage reference

For a full overview, see the [README](../README.md). This document covers
implementation details.

## Wrapper behaviour

When you run `offline-claude` the wrapper script does the following:

1. Resolves the absolute path of the current directory
2. Derives a `<project-id>` from the basename + short SHA-256 hash
3. Creates `~/.offline-claude/projects/<project-id>/.claude` if it doesn't exist
4. Ensures `~/.offline-claude/projects/<project-id>/.claude.json` exists (restores from backup if available)
5. Verifies the `offline-claude:local` Docker image exists
6. Starts the `ollama-proxy` service in detached mode
7. Runs the `claude-code` service as a one-off container

The environment is stripped down to an explicit allowlist — arbitrary host
environment variables are **not** forwarded into the container.

## CLI flags

| Flag | Description |
|---|---|
| `offline-claude` | Run with default model (`devstral-small-2:24b`) |
| `--model <name>` / `-m` | Use a specific Ollama model |
| `--help` / `-h` | Show usage and exit |
| `OLLAMA_HOST=<host>` | Override the Ollama host for LAN setups |

## Per-project state

Each directory produces a unique project ID and state directory. Running in
different directories gives you fully isolated Claude sessions.

## Warming up Ollama models

Ollama loads models on first request. To pre-load a model into VRAM before
running:

```bash
bash scripts/ollama-model-ping.sh
```

This sends a minimal chat completion request and discards the output.
