# offline-claude

offline-claude provides a secured, offline-capable runtime for Claude Code by packaging the runtime into a Docker image and orchestrating access to the Ollama service through a restricted proxy.

Prerequisites
- macOS with Docker (in my case I use it with OrbStack) (or another Docker backend)
- Docker and docker compose available
- Ollama running at a reachable IP/hostname:11434
- ~/bin exists and is on your PATH (this script will create a symlink there; it will not create the directory for you)

Installation and Usage
1. Install the wrapper script (creates ~/bin/offline-claude):

   bash scripts/install.sh

2. Build the Docker image (must be done when online):

   bash scripts/build-image.sh

3. Run offline-claude in the project directory:

   offline-claude

LAN Support

By default, offline-claude connects to Ollama running on the host machine at 127.0.0.1:11434. To use an Ollama server on your local network, set the `OLLAMA_HOST` environment variable:

   export OLLAMA_HOST=192.168.1.x
   offline-claude

This allows you to connect to Ollama servers running on other machines on your LAN, not just on localhost.

See docs/ for more detailed usage and troubleshooting.
