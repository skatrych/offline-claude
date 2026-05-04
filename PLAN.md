# Implementation Plan: 100% Offline Claude Code

## Goal
Create a host command `~/bin/offline-claude` that starts Claude Code inside Docker Compose on macOS, mounts the current directory into `/home/claude/workspace`, persists only Claude state per project, and allows Claude Code to reach only Ollama through an internal proxy container.

## Final Technical Decisions

### Runtime and installation
- Primary runtime is Docker Compose using `docker compose -f <absolute-compose-file> run --rm claude-code`.
- The user-facing command is a Bash script installed as `~/bin/offline-claude`.
- OrbStack is the primary supported stack.
- The Compose file lives in this repository and is referenced by absolute path from the wrapper.
- Installation is handled by `scripts/install.sh`.
- `scripts/install.sh` only creates or updates a symlink in `~/bin/`.
- `README.md` must explicitly state as prerequisites that `~/bin` exists and is on `PATH`.

### Networking and offline enforcement
- Offline enforcement is implemented inside Docker networking, not with macOS firewall rules.
- Architecture is:
  - `claude-code` container on `claude-internal` only
  - `ollama-proxy` container connected to `claude-internal` and `host-egress`
  - host Ollama listening on macOS `127.0.0.1:11434`
- `claude-code` uses `ANTHROPIC_BASE_URL=http://ollama-proxy:11434`.
- `ollama-proxy` forwards to `host.docker.internal:11434`.
- `claude-internal` is marked `internal: true`.
- `host-egress` is an explicit named Compose network.
- The proxy container does not publish any host ports.
- The Claude container has no direct host or external network access.

### Proxy design
- The Ollama proxy container uses `alpine/socat`.
- The proxy startup command is defined directly in `compose.yaml`.
- No custom proxy code is added in v1.

### Mounts and persistence
- The current working directory is always mounted as the main project.
- Main project mount target is `/home/claude/workspace`.
- No dynamic shared mounts are supported in v1.
- Optional extra read-only mounts are configured manually by editing commented examples in `compose.yaml`.
- Persistent state is per-project and isolated from host `~/.claude`.
- Only `/home/claude/.claude` is persisted.
- Host persistent state root is `~/.offline-claude/projects/<project-id>/`.
- Exact state mount is:
  - `~/.offline-claude/projects/<project-id>/.claude` -> `/home/claude/.claude`
- `<project-id>` is `basename + short hash of absolute current directory path`.

### Image build and versioning
- Runtime always uses a prebuilt image and never builds implicitly.
- Image builds are performed explicitly via `scripts/build-image.sh`.
- `scripts/build-image.sh` accepts `--claude-version <version>`.
- If `--claude-version` is omitted, `build-image.sh` uses a hardcoded default Claude Code version.
- Claude Code is installed in the image with:
  - `npm install -g @anthropic-ai/claude-code`
- The built image gets:
  - a versioned tag
  - a stable alias `offline-claude:local`
- Runtime always uses `offline-claude:local`.
- If the image is missing, `offline-claude` must exit with a clear message and print the exact build command to run.

### CLI and runtime configuration
- The wrapper supports:
  - `--model <name>`
  - `-m <name>`
  - `--help`
  - `-h`
- Default model is `devstral-small-2:24b`.
- No `--ollama-url` override is provided in v1.
- Runtime values are passed to Compose via explicit environment variables such as:
  - `PROJECT_DIR`
  - `CLAUDE_STATE_DIR`
  - `CLAUDE_MODEL`
- Only an explicit env allowlist is passed into the container.
- If the current directory cannot be resolved, the wrapper fails hard.

### Startup flow and validation
- `pre-flight-check.sh` and `entrypoint.sh` are separate scripts.
- `entrypoint.sh` owns startup and launches Claude Code directly.
- `CLAUDE_MODEL` is consumed by `entrypoint.sh`.
- Pre-flight checks:
  1. `/home/claude/workspace` exists and is writable
  2. `/home/claude/.claude` exists and is writable
  3. Ollama reachability via `http://ollama-proxy:11434/v1/models`
  4. internet reachability via one HTTPS probe to `https://google.com`
- Startup fails hard if Ollama is unreachable.
- Startup fails hard if the internet probe succeeds.
- Pre-flight does not verify manual optional shared mounts in v1.

### Documentation
- `README.md` gives the main overview and prerequisites.
- Detailed material lives in `docs/`.
- Shell scripts are written for Bash with strict mode enabled.

## Repository Changes

### Files to add
- `docker/ClaudeCode.Dockerfile`
- `docker/compose.yaml`
- `docker/pre-flight-check.sh`
- `docker/entrypoint.sh`
- `scripts/offline-claude`
- `scripts/build-image.sh`
- `scripts/install.sh`
- `docs/image-build.md`
- `docs/offline-networking.md`
- `docs/usage.md`

### Files to update
- `README.md`

## Detailed Implementation Steps

### Step 1: Create repository structure
Add the Docker, scripts, and docs files listed above.

Document in `README.md`:
- required host prerequisites
- that `~/bin` must already exist
- that `~/bin` must already be on `PATH`
- that OrbStack is the primary supported runtime
- that host Ollama must be running on macOS `127.0.0.1:11434`

### Step 2: Implement the Docker image
Create `docker/ClaudeCode.Dockerfile` with these requirements:
- base image: `node:22-bookworm-slim`
- create user `claude`
- create home directory `/home/claude`
- install Claude Code with `npm install -g @anthropic-ai/claude-code`
- accept an optional Claude Code version build arg
- if build arg is omitted, use the default version provided by `scripts/build-image.sh`
- copy `pre-flight-check.sh` and `entrypoint.sh` into the image
- mark scripts executable
- run as user `claude`
- use an explicit entrypoint

Important implementation rule:
- do not mount the whole `/home/claude`
- keep image-baked home layout intact
- persist only `/home/claude/.claude`

### Step 3: Implement `scripts/build-image.sh`
Create an explicit build helper with:
- Bash strict mode
- hardcoded default Claude Code version
- optional `--claude-version <version>` override
- versioned image tag creation
- local alias tagging as `offline-claude:local`

Required behavior:
- if no version is supplied, use the script default
- print the tags produced
- do not make runtime depend on implicit build behavior

### Step 4: Implement Compose networking and services
Create `docker/compose.yaml` with two services:

#### Service 1: `claude-code`
Requirements:
- uses image `offline-claude:local`
- attached only to `claude-internal`
- working directory `/home/claude/workspace`
- bind mount `${PROJECT_DIR}` -> `/home/claude/workspace`
- bind mount `${CLAUDE_STATE_DIR}` -> `/home/claude/.claude`
- environment includes:
  - `ANTHROPIC_BASE_URL=http://ollama-proxy:11434`
  - `ANTHROPIC_AUTH_TOKEN=ollama`
  - `CLAUDE_MODEL`
  - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`
  - `DISABLE_TELEMETRY=1`
  - `DISABLE_ERROR_REPORTING=1`
  - `DISABLE_FEEDBACK_COMMAND=1`
  - `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`
  - `DISABLE_GROWTHBOOK=1`
  - `DISABLE_AUTOUPDATER=1`
  - `ENABLE_CLAUDEAI_MCP_SERVERS=false`
  - `CLAUDE_CODE_DISABLE_FILE_CHECKPOINTING=1`
- uses `entrypoint.sh`

#### Service 2: `ollama-proxy`
Requirements:
- uses `alpine/socat`
- attached to both `claude-internal` and `host-egress`
- no published ports
- forwards proxy port `11434` to `host.docker.internal:11434`
- startup command is defined directly in `compose.yaml`

#### Networks
Define:
- `claude-internal` with `internal: true`
- `host-egress` as explicit named network

#### Optional shared mount example
Include a commented example in `compose.yaml` showing how to manually mount an additional host directory read-only into `/home/claude/shared/...`.

### Step 5: Implement `scripts/offline-claude`
Create the user-facing wrapper with:
- Bash strict mode
- support for `--model`, `-m`, `--help`, `-h`
- default model `devstral-small-2:24b`

Responsibilities:
- resolve current working directory
- fail hard if it cannot be resolved
- derive `<project-id>` as basename plus short hash of absolute path
- create host state path:
  - `~/.offline-claude/projects/<project-id>/.claude`
- set env vars:
  - `PROJECT_DIR`
  - `CLAUDE_STATE_DIR`
  - `CLAUDE_MODEL`
- resolve absolute path to this repository’s `docker/compose.yaml`
- check whether image `offline-claude:local` exists
- if image is missing, exit with a clear message and print the exact `scripts/build-image.sh` command
- run:
  - `docker compose -f <absolute-compose-file> run --rm claude-code`

Important implementation rule:
- do not forward arbitrary host environment variables
- pass only the explicit allowlisted env vars needed by Compose/container startup

### Step 6: Implement `scripts/install.sh`
Create a small install helper with:
- Bash strict mode
- symlink creation or replacement from repo `scripts/offline-claude` to `~/bin/offline-claude`

Constraints:
- do not create `~/bin`
- do not edit shell config
- rely on README prerequisites instead

### Step 7: Implement `docker/pre-flight-check.sh`
Create a separate pre-flight script with Bash strict mode.

Checks required:
1. `/home/claude/workspace` exists
2. `/home/claude/workspace` is writable
3. `/home/claude/.claude` exists
4. `/home/claude/.claude` is writable
5. `http://ollama-proxy:11434/v1/models` responds successfully
6. `https://google.com` must not be reachable

Failure behavior:
- any failed required mount or permission check exits non-zero
- Ollama check failure exits non-zero with clear error
- successful internet probe exits non-zero with clear error that internet connectivity was detected

Not in scope for v1:
- verifying optional manual shared mounts
- multiple internet probes
- temp file write/delete validation

### Step 8: Implement `docker/entrypoint.sh`
Create a separate startup script with Bash strict mode.

Responsibilities:
- run `pre-flight-check.sh`
- print concise startup diagnostics
- launch Claude Code using `CLAUDE_MODEL`
- use `exec` for the final Claude process

### Step 9: Write documentation

#### `README.md`
Add sections for:
- what the project does
- prerequisites
- host Ollama expectation on `127.0.0.1:11434`
- `~/bin` and `PATH` prerequisite
- install flow
- build flow
- run flow
- where detailed docs live

#### `docs/image-build.md`
Document:
- exact `scripts/build-image.sh` usage
- hardcoded default Claude Code version behavior
- optional `--claude-version`
- resulting image tags
- that runtime never builds implicitly

#### `docs/offline-networking.md`
Document:
- the final two-container architecture
- why Claude has only `claude-internal`
- why proxy has both `claude-internal` and `host-egress`
- why `claude-internal` is `internal: true`
- that no macOS firewall setup is required in this design
- known assumptions and limitations of relying on `host.docker.internal`

#### `docs/usage.md`
Document:
- install with `scripts/install.sh`
- build with `scripts/build-image.sh`
- run `offline-claude`
- run `offline-claude --model <name>`
- where project state is stored
- how to manually enable additional read-only mounts by editing `compose.yaml`
- common failure cases and their meaning

## Validation Plan

### Scenario A: Install flow
- run `scripts/install.sh`
- verify `~/bin/offline-claude` points to the repo script

### Scenario B: Image build
- run `scripts/build-image.sh`
- verify versioned tag exists
- verify `offline-claude:local` exists

### Scenario C: Default startup
- run `offline-claude` from a project directory
- verify current directory appears at `/home/claude/workspace`
- verify default model `devstral-small-2:24b` is used
- verify per-project state directory is created and mounted to `/home/claude/.claude`

### Scenario D: Explicit model
- run `offline-claude --model devstral-small-2:24b`
- verify `CLAUDE_MODEL` is passed correctly and used by startup

### Scenario E: Missing image
- remove or rename local runtime image
- run `offline-claude`
- verify it fails with a clear message and exact build command

### Scenario F: Ollama reachable through proxy
- ensure host Ollama is running on `127.0.0.1:11434`
- run `offline-claude`
- verify pre-flight check to `http://ollama-proxy:11434/v1/models` succeeds

### Scenario G: Internet blocked from Claude container
- run `offline-claude`
- verify the internet probe does not succeed
- verify startup continues only when the probe fails

### Scenario H: Internet unexpectedly reachable
- intentionally break the isolation model in a controlled test
- verify pre-flight fails hard with a clear internet-detected error

### Scenario I: Host Claude isolation
- verify host `~/.claude` is never mounted or reused

### Scenario J: Optional manual shared mount
- uncomment and configure an additional read-only mount in `compose.yaml`
- verify it is visible in the container at the documented target

## Linting and Validation Checks
- Validate Bash scripts with shell lint tooling if available.
- Validate Compose syntax with `docker compose config`.
- Validate image build by executing the documented build script.
- Validate container startup behavior with the scenarios above.

If no lint tooling exists in the repository, document the exact validation commands used during implementation.

## Don’t Do
- Do not mount host `~/.claude`.
- Do not mount the whole `/home/claude` from the host.
- Do not mount `$HOME`, `/`, or broad parent directories.
- Do not support dynamic shared mounts in v1.
- Do not silently build images during runtime.
- Do not add macOS firewall configuration to this design.
- Do not give the Claude container direct host or external network access.
- Do not publish proxy ports to the host.
- Do not forward arbitrary host environment variables into the container.
- Do not enable MCP servers.
- Do not add unrelated CLI features or pass-through arguments in v1.
- Do not add unnecessary UID/GID complexity unless a real problem is proven.

## Acceptance Criteria
- `~/bin/offline-claude` starts Claude Code through Docker Compose.
- Runtime mounts the exact current directory into `/home/claude/workspace`.
- Runtime persists only `/home/claude/.claude` per project under `~/.offline-claude/projects/<project-id>/.claude`.
- Host `~/.claude` is not mounted or used.
- Claude container is attached only to `claude-internal`.
- Proxy container is attached to `claude-internal` and `host-egress`.
- `claude-internal` is defined with `internal: true`.
- Proxy forwards to `host.docker.internal:11434` using `alpine/socat`.
- Proxy publishes no host ports.
- Runtime uses prebuilt image `offline-claude:local` only.
- Missing image causes a clear failure with an explicit build command hint.
- Claude Code is installed in the image with `npm install -g @anthropic-ai/claude-code`.
- `scripts/build-image.sh` supports optional `--claude-version` and otherwise uses a hardcoded default version.
- Wrapper supports `--model`/`-m` and defaults to `devstral-small-2:24b`.
- Startup runs `pre-flight-check.sh` before launching Claude Code.
- Pre-flight fails hard if Ollama is unreachable.
- Pre-flight fails hard if `https://google.com` is reachable from the Claude container.
- Optional extra mounts are manual `compose.yaml` edits only and may be documented with commented examples.
- README and docs describe install, build, usage, and networking behavior without hidden assumptions.
