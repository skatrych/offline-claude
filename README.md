# offline-claude

offline-claude provides a secured, offline-capable runtime for Claude Code by packaging the runtime into a Docker image and orchestrating access to the host Ollama service through a restricted proxy.

Prerequisites
- macOS with OrbStack (or another Docker backend that supports host.docker.internal)
- Docker and docker compose available
- Ollama running on the host at 127.0.0.1:11434
- ~/bin exists and is on your PATH (this script will create a symlink there; it will not create the directory for you)

Quick install and usage
1. Install the wrapper script (creates ~/bin/offline-claude):

   bash scripts/install.sh

2. Build the Docker image (must be done when online):

   bash scripts/build-image.sh

3. Run offline-claude in the project directory:

   offline-claude

See docs/ for more detailed usage and troubleshooting.
