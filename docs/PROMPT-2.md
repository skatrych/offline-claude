# PROMPT-2: Networking and Orchestration

## BIG PICTURE
You are implementing the security heart of "Offline Claude". This phase ensures that the Claude container is physically incapable of reaching the internet, while still being able to communicate with the host's Ollama service via a dedicated proxy.

## INPUT REQUIREMENTS (CONTEXT)
- A pre-built Docker image named `offline-claude:local` (from PROMPT-1).
- Host Ollama is running on `127.0.0.1:11434`.

## TASKS TO BE DONE

### 1. Create `docker/compose.yaml`
- **Networks:**
  - `claude-internal`: Must be marked `internal: true` (no external gateway).
  - `host-egress`: A standard network for the proxy to reach the host.
- **Service: `ollama-proxy`**
  - Image: `alpine/socat`.
  - Networks: Connected to *both* `claude-internal` and `host-egress`.
  - Command: `tcp-listen:11434,fork,reuseaddr tcp:host.docker.internal:11434`.
  - **Constraint:** No `ports` should be published to the host.
- **Service: `claude-code`**
  - Image: `offline-claude:local`.
  - Networks: Connected *only* to `claude-internal`.
  - Working directory: `/home/claude/workspace`.
  - Entrypoint: `/usr/local/bin/entrypoint.sh`.
  - Environment:
    - `ANTHROPIC_BASE_URL=http://ollama-proxy:11434`
    - `ANTHROPIC_AUTH_TOKEN=ollama`
    - `CLAUDE_MODEL` (passed through from the host wrapper env var)
    - `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`
    - `DISABLE_TELEMETRY=1`
    - `DISABLE_ERROR_REPORTING=1`
    - `DISABLE_FEEDBACK_COMMAND=1`
    - `CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY=1`
    - `DISABLE_GROWTHBOOK=1`
    - `DISABLE_AUTOUPDATER=1`
    - `ENABLE_CLAUDEAI_MCP_SERVERS=false`
    - `CLAUDE_CODE_DISABLE_FILE_CHECKPOINTING=1`
  - Volumes:
    - `${PROJECT_DIR}:/home/claude/workspace` (The code)
    - `${CLAUDE_STATE_DIR}:/home/claude/.claude` (Persistent state)
- Include a commented-out example for a read-only shared mount.

### 2. Implement `docker/pre-flight-check.sh`
- Use Bash strict mode (`set -euo pipefail`).
- Check that `/home/claude/workspace` **exists** and **is writable**.
- Check that `/home/claude/.claude` **exists** and **is writable**.
- Use `curl` to make an HTTP GET request to `http://ollama-proxy:11434/v1/models` and verify it returns a successful response. Do not use `nc` — TCP-only checks are not sufficient; the full HTTP endpoint must respond.
- **Security Check:** Attempt to reach `https://google.com`. The script **must fail** (exit non-zero) if the internet IS reachable.
- Print clear, concise error messages for each failure.

### 3. Implement `docker/entrypoint.sh`
- Use Bash strict mode (`set -euo pipefail`).
- Execute `/usr/local/bin/pre-flight-check.sh`.
- Print concise startup diagnostics.
- If pre-flight succeeds, `exec` into the `claude` command using the `CLAUDE_MODEL` environment variable so Claude Code replaces the shell process.

### 4. Rebuild the Docker Image
- After implementing the real `docker/entrypoint.sh` and `docker/pre-flight-check.sh`, run `bash scripts/build-image.sh` to re-bake the scripts into the image.
- **Rationale:** The image built in PROMPT-1 contains placeholder versions of both scripts. This rebuild replaces them with the fully functional implementations. The image tag `offline-claude:local` remains the same; the rebuild simply overwrites it.

## OUTPUT REQUIREMENTS (VERIFICATION)
- `docker/compose.yaml` correctly defines the isolated networking.
- `docker/pre-flight-check.sh` and `docker/entrypoint.sh` are fully functional and secure.
- The Docker image has been rebuilt and `offline-claude:local` contains the real scripts (not the placeholders from PROMPT-1).
- Running `docker compose config` (with dummy env vars) shows a valid configuration.
- Documentation in `docs/offline-networking.md` covering:
  - the two-container architecture and why it enforces isolation
  - why `claude-internal` is `internal: true`
  - why the proxy has both `claude-internal` and `host-egress`
  - that no macOS firewall configuration is required in this design
  - known assumptions and limitations of relying on `host.docker.internal`
