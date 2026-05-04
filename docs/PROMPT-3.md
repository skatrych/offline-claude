# PROMPT-3: User Experience and Integration

## BIG PICTURE
You are creating the user-facing CLI and installation flow. This phase "wraps" the Docker complexity into a simple command that feels like a native tool, while handling per-project isolation and persistence.

## INPUT REQUIREMENTS (CONTEXT)
- The Docker environment from PROMPT-2.
- User wants a command `offline-claude` available in their `PATH`.

## TASKS TO BE DONE

### 1. Create `scripts/offline-claude` (The Wrapper)
- Use Bash strict mode.
- Support `--model` / `-m` (default: `devstral-small-2:24b`).
- Support `--help` / `-h`: print usage and exit 0.
- **Logic:**
  1. Resolve the absolute path of the current directory. If it cannot be resolved, fail hard with a clear error message.
  2. Generate a `PROJECT_ID` using `basename` + a short hash of the absolute path.
  3. Create a host state directory at `~/.offline-claude/projects/<PROJECT_ID>/.claude`.
  4. Verify the image `offline-claude:local` exists; if missing, exit with a clear error message that includes the exact command to run: `bash scripts/build-image.sh`.
  5. Run `docker compose -f <absolute-path-to-docker/compose.yaml> run --rm claude-code`.
  6. Pass exactly three variables to Compose: `PROJECT_DIR`, `CLAUDE_STATE_DIR`, `CLAUDE_MODEL`. **Do not inherit or forward arbitrary host environment variables.** Use an explicit env allowlist only.

### 2. Create `scripts/install.sh`
- Create a symlink from the repo's `scripts/offline-claude` to `~/bin/offline-claude`.
- **Constraint:** Do not create `~/bin` or modify `.zshrc`/`.bashrc`. Assume user has set up their PATH as per prerequisites.

### 3. Finalize Documentation
- **`README.md`:** Main overview, prerequisites (OrbStack, Ollama on `127.0.0.1:11434`, `~/bin` must exist and be on `PATH`), install flow, build flow, run flow, and pointer to `docs/` for details.
- **`docs/usage.md`:** Detailed guide covering:
  - how to install using `scripts/install.sh`
  - how to build the image using `scripts/build-image.sh`
  - how to run `offline-claude` and `offline-claude --model <name>`
  - how per-project state is persisted under `~/.offline-claude/projects/<project-id>/.claude`
  - how to add manual read-only shared mounts by editing the commented example in `compose.yaml`
  - common failure cases and their meaning (missing image, Ollama unreachable, internet detected)

## OUTPUT REQUIREMENTS (VERIFICATION)
- `scripts/offline-claude` correctly calculates project IDs and mounts the right directories.
- `scripts/install.sh` creates a valid symlink.
- The entire flow from `install` -> `build` -> `run` is documented and works end-to-end.
- Per-project isolation is verified (running in Dir A does not see state from Dir B).
