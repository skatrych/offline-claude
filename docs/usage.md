# Usage: offline-claude

This document explains how to install, build, and run offline-claude.

Prerequisites
- OrbStack on macOS (or Docker platform supporting host.docker.internal)
- Ollama running on the host at 127.0.0.1:11434
- ~/bin exists and is on your PATH

Install
1. From the repository root run:

   bash scripts/install.sh

This creates a symlink at ~/bin/offline-claude pointing to the repo script. The script will not create ~/bin for you.

Build the image
1. When online, run:

   bash scripts/build-image.sh

This builds the image and tags it as offline-claude:<version> and offline-claude:local.

Run
1. In any project directory, run:

   offline-claude

2. Options:
   - Specify a model: offline-claude --model claude-2
   - Get help: offline-claude --help

What the wrapper does
- Resolves the absolute path of the current directory and computes a project ID composed of the directory basename and a short hash of the path.
- Creates a per-project persistent state directory at ~/.offline-claude/projects/<project-id>/.claude
- Ensures the required Docker image (offline-claude:local) exists and instructs you to run bash scripts/build-image.sh if missing.
- Invokes docker compose with a minimal environment allowlist (PROJECT_DIR, CLAUDE_STATE_DIR, CLAUDE_MODEL) to avoid leaking host env vars.

Per-project persistence
- State is stored under ~/.offline-claude/projects/<project-id>/.claude
- Running offline-claude in different directories produces different project IDs and isolated state directories.

Read-only shared mounts
- If you want to add manual read-only shared mounts, edit docker/compose.yaml and uncomment or add a bind mount with the :ro option. See the commented example.

Common failures
- Missing image: You will see an error saying offline-claude:local not found. Fix: bash scripts/build-image.sh
- Ollama unreachable: Pre-flight checks will fail when starting the container if the Ollama proxy is not reachable. Ensure Ollama is running on the host and the proxy is up.
- Internet detected: The pre-flight check will abort if external internet (e.g. https://google.com) is reachable. This indicates the isolation guarantees are not being enforced by your runtime topology.
