# Dockerfile for Offline Claude Code image
# Base image
FROM node:22-bookworm-slim

# Build argument for Claude Code version (required; script always supplies it)
ARG CLAUDE_VERSION

# Create non-root user 'claude' with home directory
RUN useradd -m -d /home/claude -s /bin/bash claude

# Install system dependencies required by pre-flight check
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally at the requested version
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_VERSION}

# Ensure the claude home layout is baked into the image.
# Note: runtime may bind-mount /home/claude/.claude only; do NOT overwrite /home/claude from host.
RUN mkdir -p /home/claude/.claude /home/claude/workspace \
    && chown -R claude:claude /home/claude

# Copy placeholder scripts into /usr/local/bin and make them executable
COPY docker/pre-flight-check.sh /usr/local/bin/pre-flight-check.sh
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/pre-flight-check.sh /usr/local/bin/entrypoint.sh

# Switch to the non-root user
USER claude

# Set working directory
WORKDIR /home/claude/workspace

# Entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
