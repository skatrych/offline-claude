# 100% Offline Claude Code

## Vision

On my MacBook I open terminal and execute command "offline-claude --model devstral-small-2:24b" and get the following:
 - it starts something like docker compose -f /absolute/path/compose-file.yaml run --rm claude-code
 - which is booting up container with current directory mounted into container's /home/${DEV_USER}/workspace (the user must exist, pre-created on docker build)
 - Container is based on node:22-bookworm-slim and has pre-installed claude code for the user $DEV_USER
 - on boot-up of the container, there is pre-flight-check.sh script that ensures all the permissions are set and ensures ping to ollama API is OK, internet check NOK
 - ollama is running on host machine on http://IP_OF_HOST_MACHINE:11434/v1
 - As result, container is operating 100% offline, with only exception: it does have networking access to ollama service on host machine.

## Usage
- option 1: open terminal and hit: offline-claude --model devstral-small-2:24b (stay in terminal and work)
- option 2: i would also consider use-case of starting my offline-claude from VSCode terminal to see the code updated/created by claude. When claude changes the code i can see it in my VSCode on host machine and when I change the code in VSCode, the files are synced into containe on host machine and when I change the code in VSCode, the files are synced into containerr


## To be decided
 - docker compose will use pre-built docker images
 - pre-build docker image will have claude code installed during docker build process (while there is internet connection)
 - the .claude directory of claude code must be persistent and could be also mounted from host machine but not from ~/.claude which is used by claude code on host machine (non-offline normal version)

## Preferred architecture
1. Ollama native on host with GPU
2. Claude Code in Docker
3. Per-project container HOME
4. Only repo mounted
5. No cloud credentials mounted
6. No MCP servers
7. Claude env vars disabling telemetry/feedback/nonessential traffic
8. Host firewall rule: Claude container may only reach host Ollama

## Other requirements

### User
DEV_USER = claude

### File access hardening
- Mount only the repo you want in Claude Code with rw flag (read/write) into $HOME/workspace
- other optional dirs from host system could be mounted with ro flag (read only) into $HOME/shared
- Do not mount
  ~/.ssh
  ~/.aws
  ~/.kube
  ~/.docker
  ~/.gitconfig
  $HOME
  /

We will likely need ENV VARs passed to container
    environment:
      ANTHROPIC_BASE_URL: "http://host.docker.internal:11434" (since i use OrbStack, the address will be different with bridge networking)
      ANTHROPIC_AUTH_TOKEN: "ollama"
      CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"
      DISABLE_TELEMETRY: "1"
      DISABLE_ERROR_REPORTING: "1"
      DISABLE_FEEDBACK_COMMAND: "1"
      CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY: "1"
      DISABLE_GROWTHBOOK: "1"
      DISABLE_AUTOUPDATER: "1"
      ENABLE_CLAUDEAI_MCP_SERVERS: "false"
      CLAUDE_CODE_DISABLE_FILE_CHECKPOINTING: "1"

default model :devstral-small-2:24b

### Networking restrictions
Claude Code container:
  can reach host Ollama only
  cannot reach internet
  cannot reach LAN
  cannot reach VPN/internal services
