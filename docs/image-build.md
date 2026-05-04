# Image build instructions for offline-claude

This document describes how to build the offline-claude Docker image used by the project.

Prerequisites
- Docker installed and running on the host (the build must run while internet is available).

Script: scripts/build-image.sh

Default version
- The script defines a hardcoded default Claude Code version: DEFAULT_CLAUDE_VERSION="0.2.29".
- You can change the default by editing scripts/build-image.sh and updating the DEFAULT_CLAUDE_VERSION value, or by supplying an explicit --claude-version when invoking the script.

Usage
- Build with the hardcoded default version:

  bash scripts/build-image.sh

- Build with an explicit version:

  bash scripts/build-image.sh --claude-version 0.2.30

Notes on behavior
- The script always passes the chosen version to docker build via --build-arg CLAUDE_VERSION=<version>. The Dockerfile expects this build arg and will install that exact version of @anthropic-ai/claude-code globally into the image.

Resulting image tags
- After a successful build the image will be tagged with two tags:
  - offline-claude:<version> (e.g. offline-claude:0.2.29)
  - offline-claude:local

Runtime and build policy
- The runtime environment (container execution) never builds or installs packages implicitly. You must run scripts/build-image.sh manually to produce the image before first use.

Verification
- After running the build script you can verify the image is present with:

  docker images | grep offline-claude

Files created by the build process
- docker/ClaudeCode.Dockerfile — the image Dockerfile
- docker/pre-flight-check.sh — placeholder pre-flight check (exits 0)
- docker/entrypoint.sh — placeholder entrypoint (prints a message and exits)
- scripts/build-image.sh — build script described above

Security note
- The image bakes a non-root user `claude` with home directory /home/claude. At runtime only /home/claude/.claude may be bind-mounted from the host; do not mount or overwrite the full /home/claude directory from the host.
