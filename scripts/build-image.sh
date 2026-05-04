#!/usr/bin/env bash
set -euo pipefail

# Build script for offline-claude image
DEFAULT_CLAUDE_VERSION="2.1.126"

usage() {
  cat <<EOF
Usage: $0 [--claude-version <version>]

Builds the Docker image for offline-claude. The script always passes
--build-arg CLAUDE_VERSION=<version> to the docker build.

Options:
  --claude-version <v>   Specify the @anthropic-ai/claude-code version to install (overrides default)
  -h, --help             Show this help
EOF
}

# Parse args
CLAUDE_VERSION=""
while [[ ${#} -gt 0 ]]; do
  case "$1" in
    --claude-version)
      if [[ ${2:-} == "" ]]; then
        echo "Error: --claude-version requires a value" >&2
        exit 2
      fi
      CLAUDE_VERSION="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$CLAUDE_VERSION" ]]; then
  CLAUDE_VERSION="$DEFAULT_CLAUDE_VERSION"
fi

IMAGE_NAME_BASE="offline-claude"
TAG_VERSION="$IMAGE_NAME_BASE:${CLAUDE_VERSION}"
TAG_LOCAL="$IMAGE_NAME_BASE:local"

echo "Building Docker image with CLAUDE_VERSION=${CLAUDE_VERSION}..."

docker build \
  -f docker/ClaudeCode.Dockerfile \
  --build-arg CLAUDE_VERSION="${CLAUDE_VERSION}" \
  -t "${TAG_VERSION}" \
  -t "${TAG_LOCAL}" \
  .

echo "Build complete. Generated tags:"
echo "  ${TAG_VERSION}"
echo "  ${TAG_LOCAL}"
