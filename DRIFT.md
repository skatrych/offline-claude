# Drift Review: `PLAN.md` vs `PROMPT-*.md`

## Overall Assessment
The three prompts broadly follow the structure and intent of `./PLAN.md`:
- `PROMPT-1.md` covers image build and foundational scripts.
- `PROMPT-2.md` covers Compose networking, proxying, and startup validation.
- `PROMPT-3.md` covers the wrapper CLI, installation flow, and user documentation.

However, there are several concrete drifts and omissions that should be corrected before using the prompts as implementation tasks.

## Findings by Prompt

### `PROMPT-1.md`

#### Drift 1: Version fallback behavior conflicts with `PLAN.md`
`PROMPT-1.md` says:
- if `CLAUDE_VERSION` is provided, install that version
- otherwise, install the latest

`PLAN.md` says:
- `scripts/build-image.sh` has a hardcoded default Claude Code version
- if `--claude-version` is omitted, the build uses that hardcoded default version

##### Why this matters
These are not the same behavior:
- “install latest” is floating and non-reproducible
- “use hardcoded default version” is pinned and reproducible

##### Recommended correction
Change `PROMPT-1.md` so that:
- the Dockerfile supports an optional `CLAUDE_VERSION` build arg
- `scripts/build-image.sh` always passes either the user-provided version or the script default
- the prompt does not instruct the implementer to fall back to “latest”

#### Drift 2: Missing explicit entrypoint requirement
`PLAN.md` explicitly requires the Docker image to use an explicit entrypoint.

`PROMPT-1.md` mentions copying placeholder scripts, but does not explicitly require:
- configuring the Dockerfile entrypoint to use `entrypoint.sh`

##### Recommended correction
Add an explicit Dockerfile requirement to set the image entrypoint to the copied `entrypoint.sh`.

#### Drift 3: Script executability inside the image is underspecified
`PLAN.md` explicitly requires that `pre-flight-check.sh` and `entrypoint.sh` are copied into the image and marked executable.

`PROMPT-1.md` says to copy placeholder scripts but does not explicitly require making them executable in the Docker image build.

##### Recommended correction
Add a requirement that both scripts are marked executable during image build.

#### Omission 1: Documentation scope is narrower than `PLAN.md`
`PROMPT-1.md` requires documentation in `docs/image-build.md`, which is good, but it does not explicitly mention some plan requirements that should appear there:
- hardcoded default Claude Code version behavior
- optional `--claude-version`
- resulting image tags
- runtime never builds implicitly

##### Recommended correction
Align the prompt’s documentation requirements with the exact `docs/image-build.md` expectations from `PLAN.md`.

---

### `PROMPT-2.md`

#### Drift 4: Missing `CLAUDE_MODEL` environment variable
`PLAN.md` requires runtime values passed via env vars including:
- `CLAUDE_MODEL`

`PROMPT-2.md` includes `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, and telemetry-disabling variables, but does not explicitly include `CLAUDE_MODEL`.

##### Why this matters
`entrypoint.sh` is expected to consume `CLAUDE_MODEL` and launch Claude Code with the chosen/default model.

##### Recommended correction
Explicitly require `CLAUDE_MODEL` in the `claude-code` service environment.

#### Drift 5: Missing `working_dir` requirement
`PLAN.md` explicitly requires:
- working directory `/home/claude/workspace`

`PROMPT-2.md` does not explicitly require `working_dir` in `docker/compose.yaml`.

##### Recommended correction
Add `working_dir: /home/claude/workspace` to the `claude-code` service requirements.

#### Drift 6: Missing explicit `entrypoint.sh` usage in Compose
`PLAN.md` requires that the service uses `entrypoint.sh`.

`PROMPT-2.md` requires implementing `entrypoint.sh`, but does not explicitly say that `claude-code` in Compose should use it.

##### Recommended correction
Add an explicit requirement that the `claude-code` service uses `entrypoint.sh` as its entrypoint.

#### Drift 7: Pre-flight mount validation is weaker than in `PLAN.md`
`PROMPT-2.md` says:
- check if `/home/claude/workspace` and `/home/claude/.claude` are writable

`PLAN.md` says pre-flight must check both for each path:
- exists
- is writable

##### Recommended correction
Update the prompt to require explicit existence checks in addition to writability checks.

#### Omission 2: `docs/offline-networking.md` scope is incomplete
`PLAN.md` says `docs/offline-networking.md` should document:
- the final two-container architecture
- why Claude has only `claude-internal`
- why proxy has both `claude-internal` and `host-egress`
- why `claude-internal` is `internal: true`
- that no macOS firewall setup is required in this design
- known assumptions and limitations of relying on `host.docker.internal`

`PROMPT-2.md` only requires documentation for:
- two-container architecture
- proxy logic

##### Recommended correction
Expand `PROMPT-2.md` documentation requirements to include:
- no macOS firewall requirement
- assumptions and limitations of `host.docker.internal`

---

### `PROMPT-3.md`

#### Drift 8: Missing `--help` / `-h` support
`PLAN.md` explicitly requires wrapper support for:
- `--help`
- `-h`

`PROMPT-3.md` only requires:
- `--model`
- `-m`

##### Recommended correction
Add `--help` and `-h` to the wrapper requirements.

#### Drift 9: Compose invocation is not explicit enough
`PLAN.md` requires runtime to use:
- `docker compose -f <absolute-compose-file> run --rm claude-code`

`PROMPT-3.md` says to run:
- `docker compose run --rm claude-code`

This omits the important requirement that the wrapper must use the repository Compose file via an absolute path.

##### Recommended correction
Update `PROMPT-3.md` to explicitly require:
- resolving the absolute path to this repository’s `docker/compose.yaml`
- invoking Compose with `-f <absolute-compose-file>`

#### Omission 3: README scope is narrower than `PLAN.md`
`PLAN.md` requires `README.md` to include:
- what the project does
- prerequisites
- host Ollama expectation on `127.0.0.1:11434`
- `~/bin` and `PATH` prerequisite
- install flow
- build flow
- run flow
- where detailed docs live

`PROMPT-3.md` only mentions:
- main overview
- installation instructions
- prerequisites

##### Recommended correction
Expand `PROMPT-3.md` README requirements to fully match `PLAN.md`.

#### Omission 4: `docs/usage.md` scope is narrower than `PLAN.md`
`PLAN.md` requires `docs/usage.md` to document:
- install with `scripts/install.sh`
- build with `scripts/build-image.sh`
- run `offline-claude`
- run `offline-claude --model <name>`
- where project state is stored
- how to manually enable additional read-only mounts by editing `compose.yaml`
- common failure cases and their meaning

`PROMPT-3.md` only mentions:
- persistence behavior
- changing models
- adding manual mounts

##### Recommended correction
Expand `docs/usage.md` requirements in `PROMPT-3.md` to fully match `PLAN.md`.

---

## Internal Consistency Note on `PLAN.md`
There is one small wording ambiguity in `PLAN.md` itself that affects prompt interpretation.

### Ambiguity: Dockerfile optional version vs script default version
`PLAN.md` contains both of these ideas:
- the Dockerfile accepts an optional Claude Code version build arg
- if no version is provided, `build-image.sh` uses a hardcoded default version

This is fine if interpreted as:
- the Dockerfile supports optional version input
- in normal usage, `build-image.sh` always passes either the user-selected version or the script default

But this can be misread as:
- the Dockerfile itself should fall back to “latest” if no build arg is provided

### Recommendation
Make the prompts explicit that:
- the Dockerfile supports `CLAUDE_VERSION`
- `build-image.sh` is responsible for always passing the concrete version used in standard builds
- reproducibility comes from the script default, not a floating installer fallback

---

## Summary of Required Prompt Fixes
Before executing the prompts as separate agentic tasks, the following changes are recommended:

1. In `PROMPT-1.md`, remove or replace the “otherwise install latest” instruction.
2. In `PROMPT-1.md`, explicitly require setting the Docker image entrypoint.
3. In `PROMPT-1.md`, explicitly require marking copied scripts executable in the image.
4. In `PROMPT-1.md`, align `docs/image-build.md` expectations with `PLAN.md`.
5. In `PROMPT-2.md`, explicitly include `CLAUDE_MODEL` in the `claude-code` environment.
6. In `PROMPT-2.md`, explicitly require `working_dir: /home/claude/workspace`.
7. In `PROMPT-2.md`, explicitly require Compose to use `entrypoint.sh`.
8. In `PROMPT-2.md`, strengthen pre-flight checks from only “writable” to “exists and writable”.
9. In `PROMPT-2.md`, expand networking documentation requirements to include no-firewall design and `host.docker.internal` caveats.
10. In `PROMPT-3.md`, add `--help` and `-h` support.
11. In `PROMPT-3.md`, require `docker compose -f <absolute-compose-file> run --rm claude-code` explicitly.
12. In `PROMPT-3.md`, expand `README.md` requirements to fully match `PLAN.md`.
13. In `PROMPT-3.md`, expand `docs/usage.md` requirements to fully match `PLAN.md`.

## Bottom Line
The prompts are close, but not yet fully faithful to `./PLAN.md`. The largest functional drift is the version fallback behavior in `PROMPT-1.md`, and the largest runtime omissions are the missing `CLAUDE_MODEL`, missing explicit Compose entrypoint/working directory, and missing wrapper help flags.