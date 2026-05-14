# Offline networking design

## Overview
The runtime uses two containers:
- `claude-code`: runs Claude Code and has no direct external network path.
- `ollama-proxy`: an nginx reverse proxy that relays only Ollama traffic from
  `claude-code` to the host Ollama endpoint.

This split enforces isolation because Claude is not attached to any network with
direct internet egress. The nginx proxy is necessary because Ollama rejects
requests whose `Host` header isn't `localhost` ([ollama/ollama#3269](https://github.com/ollama/ollama/issues/3269)).

A static config (`docker/ollama-proxy.nginx.conf`) and a template version
(`docker/ollama-proxy.nginx.conf.template`) are included for reference.

## Why `claude-internal` is `internal: true`
`claude-internal` is marked `internal: true` so Docker does not provide an external gateway for that network. Any service attached only to this network cannot directly access the internet.

## Why proxy has both networks
`ollama-proxy` is attached to:
- `claude-internal`: to accept traffic from `claude-code`
- `host-egress`: to reach `host.docker.internal:11434` (host Ollama)

`claude-code` is attached only to `claude-internal`, so it can talk to `ollama-proxy` but cannot use `host-egress` itself.

## Why no macOS firewall changes are required
Network isolation is enforced by Docker network topology (service-to-network attachment and `internal: true`), not by host firewall rules. No additional macOS firewall configuration is required for this design.

## Assumptions and limitations
- Assumes `host.docker.internal` resolves correctly in macOS/OrbStack.
- If host Docker backend behavior differs, proxy-to-host connectivity may need adjustment.
- Isolation depends on preserving this compose topology; attaching `claude-code` to additional egress-capable networks can break guarantees.
