# Building the Docker image

The offline-claude runtime uses a pre-built image. Build it while you have internet
access — the runtime never builds or installs packages.

## Prerequisites

- Docker installed and running

## Build

```bash
# Build with the default Claude Code version (currently 2.1.126):
bash scripts/build-image.sh

# Build with a specific version:
bash scripts/build-image.sh --claude-version 2.1.130
```

## What it does

The script installs Claude Code into a `node:22-bookworm-slim` image via npm and
tags the result with two labels:

- `offline-claude:<version>` — e.g. `offline-claude:2.1.126`
- `offline-claude:local` — the stable tag used by the runtime

The runtime always uses `offline-claude:local`. If it's missing, `offline-claude`
will exit with a clear message and the exact build command to run.

## Verifying

```bash
docker images | grep offline-claude
```

## Updating the default version

Edit `DEFAULT_CLAUDE_VERSION` in `scripts/build-image.sh` or pass
`--claude-version` explicitly.

## Security notes

- The image creates a non-root user `claude` with home at `/home/claude`
- Only `/home/claude/.claude` should be bind-mounted from the host — never mount the full `/home/claude`
- Claude env vars in `docker/compose.yaml` disable all telemetry, feedback, and cloud MCP servers
