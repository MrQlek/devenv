# Docker Dev Env

Reproducible, containerized development environments for Go projects, with optional Claude Code integration.

## Overview

Two Docker image variants are available:

| Image | Description |
|---|---|
| `golang-dev` | Go + dev tools (gopls, delve, air, fzf, ripgrep, fd, jq, vim) |
| `golang-claude-dev` | Extends `golang-dev` with Claude Code CLI pre-installed |

Containers run as a non-root user (`dockergo`) matching your host UID/GID. The Go module cache is persisted across sessions via a named volume at `~/.dockerdevenv/go-mod/<image-version>/`.

## Requirements

- Docker with Compose plugin (`docker compose`)
- GNU Make

## Building Images

> **Note:** Tagged builds require a git tag matching `golang/*` on the current commit (e.g. `golang/v1.0.0`). For local development, use the `-dev` variants which skip this requirement.

### Go dev image

```bash
# Production (requires golang/* git tag)
make build-golang

# Local dev
make build-golang-dev
```

### Go + Claude Code image

```bash
# Production (requires golang-dev:<tag> base image)
make build-golang-claude

# Local dev (requires golang-dev:dev base image)
make build-golang-claude-dev
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

Four commands become available:

### `devenv [language] [version] [ports] [public-ports]`

Starts a new container with your current directory mounted at `/workspace`.

`ports` are bound to `127.0.0.1` (localhost only). `public-ports` are bound to `0.0.0.0` (all interfaces — use when you need the port reachable from other machines or devices on the network).

```bash
# Go environment (dev image)
devenv golang dev

# Go + Claude Code environment
devenv golang-claude dev

# Localhost-only ports (comma-separated)
devenv golang-claude dev 3000,9090

# All-interfaces ports
devenv golang-claude dev "" 8080,8443

# Mix: some localhost, some public
devenv golang-claude dev 3000 8080
```

Defaults: `language=golang`, `version=dev`

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

### `devenv-inspect [language] [version] [ports] [public-ports] [--raw]`

Prints the merged Docker Compose config plus the runtime flags that would be passed to `docker compose run`. Use it to verify what `devenv` would actually do without launching a container.

```bash
devenv-inspect golang dev
devenv-inspect golang-claude dev 3000 --raw   # keep ${VAR} placeholders
```

## Claude Code Configuration

When using `golang-claude`, the following are passed into the container:

| Host path | Container path |
|---|---|
| `~/.dockerdevenv/claude/projects/<project>/` | `/home/dockergo/.claude/` |
| `~/.dockerdevenv/claude/projects/<project>.json` | `/home/dockergo/.claude.json` |
| `$ANTHROPIC_API_KEY` | `$ANTHROPIC_API_KEY` |

The project name is derived from the absolute path of your current directory (slashes replaced with dashes).

> **Security note — `ANTHROPIC_API_KEY`:** Passing the key via environment variable exposes it in `docker inspect <container>`, in `/proc/<pid>/environ` of every process inside the container, and to any binary Claude spawns. Prefer `claude login` inside the container on first use — credentials are then stored in the mounted `~/.claude/` directory and persist across sessions. Reserve the env-var path for non-interactive or scripted runs where browser-based login is not possible.

## Debugger

Port `2345` is exposed in Go environments for remote debugging with Delve. A convenience alias is available inside the container:

```bash
dlv-debug   # equivalent to: dlv debug --headless --listen=:2345 --api-version=2
```

## Adding a New Language

The Compose layer stacks files instead of duplicating them. To add a new language `<lang>`:

1. Create `compose/<lang>.yml` with only language-specific bits (image overrides, caches, debugger port, extra caps, etc.). Service name must be `devenv`.
2. Build a `<lang>-dev` image (Dockerfile under `<lang>/`).
3. `devenv <lang>` will stack `compose/base.yml` + `compose/<lang>.yml`.
4. `devenv <lang>-claude` will additionally stack `compose/claude.yml`. The combined image must be named `<lang>-claude-dev`.

If the language needs per-environment shell-side prep (e.g., creating cache dirs, prompting for config on first run), drop a file at `shell/lib/<lang>.sh` that defines `_devenv_lib_<name>_hook`. The hook is discovered automatically, receives the language string and project slug, and may write to any `_DEVENV_PREP_*` global. See `shell/lib/claude.sh` for the reference implementation.

Optional `compose/<lang>-claude.yml` may exist for combo-specific overrides; it is sourced only when present.
