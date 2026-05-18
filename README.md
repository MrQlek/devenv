# Docker Dev Env

Reproducible, containerized development environments for Go projects, with optional Claude Code integration.

## Overview

Two Docker image variants are available:

| Image | Description |
|---|---|
| `golang-dev` | Go + dev tools (gopls, delve, air, fzf, ripgrep, fd, jq, vim) |
| `golang-claude-dev` | Extends `golang-dev` with Claude Code CLI pre-installed |

Containers run as a non-root user (`dockergo`) matching your host UID/GID. The Go module cache is persisted across sessions via a named volume at `~/.dockerdevenv/go-mod/<version>/`.

## Requirements

- Docker with Compose plugin (`docker compose`) or `docker-compose`
- GNU Make

## Building Images

> **Note:** Tagged builds require a git tag matching `golang/*` on the current commit (e.g. `golang/v1.0.0`). For local development, use the `-dev` variants which skip this requirement.

### Go dev image

```bash
# Production (requires golang/* git tag)
make build-golang GO_RELEASE=1.24

# Local dev
make build-golang-dev GO_RELEASE=1.24
```

### Go + Claude Code image

```bash
# Production (requires golang-dev:<version>-<tag> base image)
make build-golang-claude GO_RELEASE=1.24

# Local dev (requires golang-dev:<version>-dev base image)
make build-golang-claude-dev GO_RELEASE=1.24
```

List available golang tags:

```bash
make list-golang-tags
```

## Usage

Source the shell helpers in your `.bashrc` or `.zshrc`:

```bash
source /path/to/this/repo/shell/dev.sh
```

Three commands become available:

### `devenv [language] [release] [version] [ports]`

Starts a new container with your current directory mounted at `/workspace`.

```bash
# Go environment (dev image)
devenv golang 1.24 dev

# Go + Claude Code environment
devenv golang-claude 1.24 dev

# With extra exposed ports (comma-separated)
devenv golang-claude 1.24 dev 8080,9090
```

Defaults: `language=golang`, `release=1.26`, `version=dev`

For `golang-claude`, you will be prompted to choose a Claude config scope (project-specific, per-language, or global) on first run. Configs are stored under `~/.dockerdevenv/claude/`.

### `devenv-connect [language]`

Opens an additional bash shell in a running container.

```bash
devenv-connect golang-claude
```

### `devenv-exec [language] <command> [args...]`

Runs a single command inside a running container.

```bash
devenv-exec golang go test ./...
devenv-exec golang-claude claude --version
```

## Claude Code Configuration

When using `golang-claude`, the following are passed into the container:

| Host path | Container path |
|---|---|
| `~/.dockerdevenv/claude/projects/<project>/` | `/home/dockergo/.claude/` |
| `~/.dockerdevenv/claude/projects/<project>.json` | `/home/dockergo/.claude.json` |
| `$ANTHROPIC_API_KEY` | `$ANTHROPIC_API_KEY` |

The project name is derived from the absolute path of your current directory (slashes replaced with dashes).

## Debugger

Port `2345` is exposed in all environments for remote debugging with Delve. A convenience alias is available inside the container:

```bash
dlv-debug   # equivalent to: dlv debug --headless --listen=:2345 --api-version=2
```
