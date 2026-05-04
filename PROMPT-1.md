# PROMPT-1: Core Image and Build Tooling

## BIG PICTURE
You are building the foundation of "Offline Claude": a secure, versioned Docker image containing Claude Code, and the scripts to build it. This image must be built while internet is available, but is designed to run in a strictly isolated environment later.

## INPUT REQUIREMENTS (CONTEXT)
- Target OS: macOS (OrbStack)
- Base Image: `node:22-bookworm-slim`
- Project Name: `offline-claude`
- Target Image Tag: `offline-claude:local`

## TASKS TO BE DONE

### 1. Create `docker/ClaudeCode.Dockerfile`
- Create a non-root user `claude` with home directory `/home/claude`.
- Install system dependencies: `curl` and `ca-certificates` (required by the pre-flight check script implemented in PROMPT-2).
- Install Claude Code globally using `npm install -g @anthropic-ai/claude-code`.
- **Constraint:** Accept a build argument `CLAUDE_VERSION`. If provided, install that specific version. The build arg is always supplied by `scripts/build-image.sh` (either from `--claude-version` or from its hardcoded default), so the Dockerfile does not need a fallback to latest.
- Set the working directory to `/home/claude/workspace`.
- **Constraint:** Do not mount or overwrite the whole `/home/claude` directory from the host. The image bakes its own home layout. Only `/home/claude/.claude` will be bind-mounted at runtime. This constraint must be reflected in how the Dockerfile structures the home directory.
- Copy dummy/placeholder `entrypoint.sh` and `pre-flight-check.sh` (which will be fully implemented in later prompts) into `/usr/local/bin/` and mark both executable (`chmod +x`).
- Ensure the user `claude` owns its home directory.
- Switch to user `claude` for the final execution.
- Define an explicit `ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]` in the Dockerfile.

### 2. Create `scripts/build-image.sh`
- Use Bash strict mode (`set -euo pipefail`).
- Define a hardcoded `DEFAULT_CLAUDE_VERSION` (e.g., `0.2.29`).
- Support an optional argument `--claude-version <v>`.
- **Logic:** Execute `docker build` using the Dockerfile above, always passing `--build-arg CLAUDE_VERSION=<version>` where `<version>` is either the user-supplied value or the hardcoded script default. Never rely on the Dockerfile to pick a version silently.
- **Tagging:** 
  1. Tag with the specific version: `offline-claude:<version>`.
  2. Tag with the stable alias: `offline-claude:local`.
- Print the generated tags upon success.

### 3. Create Placeholder Scripts (for Image Build)
- Create `docker/pre-flight-check.sh`: A simple script that exits 0.
- Create `docker/entrypoint.sh`: A script that prints "Placeholder Entrypoint" and exits 0.
- Both must be marked executable.

## OUTPUT REQUIREMENTS (VERIFICATION)
- `docker/ClaudeCode.Dockerfile` exists and follows the non-root/versioning rules.
- `scripts/build-image.sh` is executable and correctly handles tags and build args.
- Running `bash scripts/build-image.sh` results in a successful image build visible via `docker images | grep offline-claude`.
- Documentation in `docs/image-build.md` covering:
  - exact `scripts/build-image.sh` usage with and without `--claude-version`
  - what the hardcoded default version is and how to change it
  - the two resulting image tags (`offline-claude:<version>` and `offline-claude:local`)
  - that runtime **never builds implicitly** — the user must always run `build-image.sh` manually before first use
