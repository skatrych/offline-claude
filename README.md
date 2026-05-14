# offline-claude

Run Claude Code in a Docker container that can **only** reach your local Ollama instance — no internet, no cloud, nothing else.

<p align="center">
  <strong>100% offline. Zero cloud credentials. Zero internet egress.</strong>
</p>

## What it does

offline-claude packages Claude Code into a Docker image and runs it inside a
compose setup that enforces network isolation:

```
┌─────────────────────────────────────────────────┐
│                    Your macOS                    │
│                                                 │
│  ┌──────────────┐       ┌──────────────┐       │
│  │  claude-code  │ ────▶│ ollama-proxy │──┐    │
│  │  (no internet)│      │  (nginx)     │  │    │
│  │              │◀──────│             │  │    │
│  └──────────────┘      └──────────────┘  │    │
│          │                    │          │    │
│          │         host.docker.internal   │    │
│          │                    │          │    │
│          │              ┌───────────┐    │    │
│          │              │  Ollama   │◀───┘    │
│          │              │  :11434   │         │
│          └──────────────┴───────────┘         │
│              (your project dir)               │
└─────────────────────────────────────────────────┘
```

- `claude-code` is attached to an **internal-only** Docker network — no internet path exists
- `ollama-proxy` bridges the two networks: accepts from claude-code, forwards to host Ollama
- Your project directory is mounted into the container as the workspace
- Per-project state is persisted under `~/.offline-claude/projects/<project-id>/`
- All telemetry, feedback, and cloud MCP servers are disabled by default

## Prerequisites

- **macOS** with Docker (tested with OrbStack; works with Docker Desktop too)
- **Ollama** running on `127.0.0.1:11434`
- **`~/bin`** exists and is on your `PATH`

## Quick start

```bash
# 1. Install the wrapper script (creates ~/bin/offline-claude)
bash scripts/install.sh

# 2. Build the Docker image (requires internet)
bash scripts/build-image.sh

# 3. Use it from any project directory
cd /path/to/your/project
offline-claude
```

That's it. Claude Code runs isolated with only local Ollama access.

## Usage

```
offline-claude                    # use default model (devstral-small-2:24b)
offline-claude --model qwen3:8b  # specify a different model
offline-claude -m qwen3:8b       # short form
offline-claude --help            # show help
```

### Per-project state

Each project directory gets its own isolated state stored at:

```
~/.offline-claude/projects/<project-id>/.claude
```

The `<project-id>` is derived from the directory's basename plus a short hash of the
absolute path, so you won't accidentally mix state between projects.

### LAN Ollama servers

By default, offline-claude connects to Ollama on the local machine. To use an Ollama
server on another machine on your LAN:

```bash
export OLLAMA_HOST=192.168.1.x
offline-claude
```

### Read-only shared mounts

If you need additional host directories available inside the container, edit
`docker/compose.yaml` and add a bind mount with the `:ro` flag:

```yaml
volumes:
  - ${PROJECT_DIR}:/home/claude/workspace
  - ${CLAUDE_STATE_DIR}:/home/claude/.claude
  - /absolute/path/to/shared:/home/claude/shared:ro
```

## Updating the image

Claude Code updates frequently. Rebuild the image whenever you want a new version:

```bash
# Rebuild with the default version (update DEFAULT_CLAUDE_VERSION in build-image.sh first)
bash scripts/build-image.sh

# Or specify an explicit version
bash scripts/build-image.sh --claude-version 2.1.130
```

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `offline-claude:local not found` | Image hasn't been built yet | Run `bash scripts/build-image.sh` |
| `Ollama proxy is not reachable` | Ollama isn't running on the host | Start Ollama, verify `localhost:11434` |
| `Internet egress is reachable` | Network isolation is broken (rare) | Check your Docker backend config; verify `claude-internal` is `internal: true` |
| Pre-flight check fails | Container can't reach the proxy | Ensure `OLLAMA_HOST` is set correctly for LAN setups |

## Security model

- No cloud credentials are ever mounted into the container
- `~/.ssh`, `~/.aws`, `~/.kube`, `~/.docker` are never accessible
- The Claude container can reach **only** the Ollama proxy — nothing else
- All telemetry, analytics, and feedback channels are disabled via environment variables
- Network isolation is enforced by Docker topology (`internal: true`), not firewall rules

See [docs/offline-networking.md](docs/offline-networking.md) for networking details.
