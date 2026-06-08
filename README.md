# Docker Dev Env

Reproducible, containerized development environments for Go and Python projects, with optional Claude Code integration.

## Overview

Two Docker image variants are available:

| Image | Description |
|---|---|
| `devenv-image-golang` | Go + dev tools (gopls, delve, air, fzf, ripgrep, fd, jq, vim) |
| `devenv-image-golang-claude` | Extends `devenv-image-golang` with Claude Code CLI pre-installed |
| `devenv-image-python` | Python 3.14 + uv + debugpy + ruff + mypy + dev tools (fzf, ripgrep, fd, jq, vim) |
| `devenv-image-python-claude` | Extends `devenv-image-python` with Claude Code CLI pre-installed |
| `devenv-image-typescript` | Node 24 LTS + TypeScript + tsx + `@vscode/vsce` + `eas-cli` + dev tools (fzf, ripgrep, fd, jq, vim) |
| `devenv-image-typescript-claude` | Extends `devenv-image-typescript` with Claude Code CLI pre-installed |

Containers run as a non-root user (`devuser`) matching your host UID/GID. Per-language caches are persisted on the host under `~/.devenv/`:

| Language | Host path | Purpose |
|---|---|---|
| Go | `~/.devenv/go-mod/<version>/` | Module cache |
| Go | `~/.devenv/go-cache/<version>/` | Build cache |
| Python | `~/.devenv/uv-cache/<version>/` | uv download cache (wheels/sdists) |
| Python | `~/.devenv/uv-share/<version>/` | `uv tool install` environments |
| Python | `~/.devenv/uv-bin/<version>/` | uv tool shims (`~/.local/bin`) |
| TypeScript | `~/.devenv/npm-cache/<version>/` | npm download cache |
| TypeScript | `~/.devenv/expo/<version>/` | Expo / EAS state (auth tokens, etc.) |

## Requirements

- Docker with Compose plugin (`docker compose`)
- GNU Make

## Building Images

> **Note:** Each image has its own tag namespace. Tagged builds require the matching tag to be on the current commit; `--exact-match` enforces this. For local development, use the `-dev` variants which skip the tag requirement.
>
> | Image | Tag namespace | Example |
> |---|---|---|
> | `devenv-image-golang` | `golang/*` | `golang/v1.0.0` |
> | `devenv-image-golang-claude` | `golang-claude/*` | `golang-claude/v1.0.0` |
> | `devenv-image-python` | `python/*` | `python/v1.0.0` |
> | `devenv-image-python-claude` | `python-claude/*` | `python-claude/v1.0.0` |
> | `devenv-image-typescript` | `typescript/*` | `typescript/v1.0.0` |
> | `devenv-image-typescript-claude` | `typescript-claude/*` | `typescript-claude/v1.0.0` |

### Go dev image

```bash
# Production (requires golang/* tag on HEAD)
make build-golang

# Local dev
make build-golang-dev
```

### Python dev image

```bash
# Production (requires python/* tag on HEAD)
make build-python

# Local dev
make build-python-dev
```

### TypeScript dev image

For both VSCode extension development (`vsce package`, `tsc`) and Expo mobile apps (`npx create-expo-app`, `eas-cli`).

```bash
# Production (requires typescript/* tag on HEAD)
make build-typescript

# Local dev
make build-typescript-dev
```

### Python + Claude Code image

The python-claude image is versioned independently from the python base. `build-python-claude` requires a `python-claude/*` tag on HEAD, and uses the nearest `python/*` tag reachable from HEAD as its base.

```bash
# Production (requires python-claude/* tag on HEAD;
# uses the most recent python/* tag in history as base)
make build-python-claude

# Local dev (defaults to devenv-image-python:dev as base;
# override with DEV_BASE=<tag> to pin a specific base version)
make build-python-claude-dev
make build-python-claude-dev DEV_BASE=v1.0.0
```

The resolved base image (`devenv-image-python:<tag>`) must already exist locally — build it from the relevant commit if not.

### Go + Claude Code image

The claude image is versioned independently from the go base. `build-golang-claude` requires a `golang-claude/*` tag on HEAD, and uses the nearest `golang/*` tag reachable from HEAD (`git describe --abbrev=0`) as its base — so bumping claude does not require re-tagging or rebuilding `devenv-image-golang`.

```bash
# Production (requires golang-claude/* tag on HEAD;
# uses the most recent golang/* tag in history as base)
make build-golang-claude

# Local dev (defaults to devenv-image-golang:dev as base;
# override with DEV_BASE=<tag> to pin a specific base version)
make build-golang-claude-dev
make build-golang-claude-dev DEV_BASE=v1.0.0
```

The resolved base image (`devenv-image-golang:<tag>`) must already exist locally — build it from the relevant commit if not.

### TypeScript + Claude Code image

The typescript-claude image is versioned independently from the typescript base. `build-typescript-claude` requires a `typescript-claude/*` tag on HEAD, and uses the nearest `typescript/*` tag reachable from HEAD as its base.

```bash
# Production (requires typescript-claude/* tag on HEAD;
# uses the most recent typescript/* tag in history as base)
make build-typescript-claude

# Local dev (defaults to devenv-image-typescript:dev as base;
# override with DEV_BASE=<tag> to pin a specific base version)
make build-typescript-claude-dev
make build-typescript-claude-dev DEV_BASE=v1.0.0
```

The resolved base image (`devenv-image-typescript:<tag>`) must already exist locally — build it from the relevant commit if not.

List available tags:

```bash
make list-golang-tags
make list-golang-claude-tags
make list-python-tags
make list-python-claude-tags
make list-typescript-tags
make list-typescript-claude-tags
```

## Usage

Source the shell helpers in your `.bashrc` or `.zshrc`:

```bash
source /path/to/this/repo/shell/devenv.sh
```

Tab completion for `devenv`, `devenv-inspect`, `devenv-connect`, and `devenv-exec` is enabled automatically (bash and zsh). Language candidates are derived from your locally-built `devenv-image-*` images, so only buildable/runnable combos are offered.

Four commands become available:

### `devenv [language] [version] [ports] [public-ports]`

Starts a new container with your current directory mounted at `/workspace`.

`ports` are bound to `127.0.0.1` (localhost only). `public-ports` are bound to `0.0.0.0` (all interfaces — use when you need the port reachable from other machines or devices on the network).

```bash
# Go environment (dev image)
devenv golang dev

# Go + Claude Code environment
devenv golang-claude dev

# Python environment
devenv python dev

# Python + Claude Code environment
devenv python-claude dev

# TypeScript environment (VSCode extensions, Expo apps)
devenv typescript dev

# TypeScript + Claude Code environment
devenv typescript-claude dev

# Localhost-only ports (comma-separated)
devenv golang-claude dev 3000,9090
devenv python dev 8000,5678

# All-interfaces ports
devenv golang-claude dev "" 8080,8443

# Mix: some localhost, some public
devenv golang-claude dev 3000 8080
```

Defaults: `language=golang`, `version=dev`

For `golang-claude`, you will be prompted to choose a Claude config scope (project-specific, per-language, or global) on first run. Configs are stored under `~/.devenv/claude/`.

For `python` and `python-claude`, project packages (`.venv`) are stored inside the workspace directory and persist naturally via the host mount. The uv download cache and tool installations are persisted under `~/.devenv/` (see the table above).

For `python-claude`, you will be prompted to choose a Claude config scope on first run, identical to `golang-claude`. Configs are stored under `~/.devenv/claude/`.

For `typescript-claude`, you will be prompted to choose a Claude config scope on first run, identical to `golang-claude`. Configs are stored under `~/.devenv/claude/`.

For `typescript`, per-project `node_modules` live in the workspace and persist via the host mount; the npm download cache and Expo/EAS state are persisted under `~/.devenv/` (see the table above). Port `8081` (Metro bundler) is published on `0.0.0.0` so a phone on the same LAN can connect; the Node inspector on `9229` stays on `127.0.0.1`.

#### Hiding files from the container

The container always has `/workspace/.devenv_exclude` mounted as an in-memory tmpfs. Anything you place under `.devenv_exclude/` on the host stays on the host — the container sees the directory as empty. Useful for API keys, SSH credentials, or anything else you don't want a coding agent to read.

Organize secrets under subdirectories if you need structure:

```
.devenv_exclude/
├── aws/credentials
├── env-prod
└── ssh/id_rsa
```

To mask a path that's not already inside `.devenv_exclude/` (e.g. a `.env` at the workspace root), move or symlink it under `.devenv_exclude/`. Add `.devenv_exclude/` to your `.gitignore`.

### `devenv-connect [language]`

Opens an additional bash shell in a running container.

```bash
devenv-connect golang-claude
devenv-connect python
```

### `devenv-exec [language] <command> [args...]`

Runs a single command inside a running container.

```bash
devenv-exec golang go test ./...
devenv-exec golang-claude claude --version
devenv-exec python uv run pytest
```

### `devenv-inspect [language] [version] [ports] [public-ports] [--raw]`

Prints the merged Docker Compose config plus the runtime flags that would be passed to `docker compose run`. Use it to verify what `devenv` would actually do without launching a container.

```bash
devenv-inspect golang dev
devenv-inspect golang-claude dev 3000 --raw   # keep ${VAR} placeholders
devenv-inspect python dev
```

## Claude Code Configuration

When using `golang-claude`, the following are passed into the container:

| Host path | Container path |
|---|---|
| `~/.devenv/claude/projects/<project>/` | `/home/devuser/.claude/` |
| `~/.devenv/claude/projects/<project>.json` | `/home/devuser/.claude.json` |
| `$ANTHROPIC_API_KEY` | `$ANTHROPIC_API_KEY` |

The project name is derived from the absolute path of your current directory (slashes replaced with dashes).

> **Security note — `ANTHROPIC_API_KEY`:** Passing the key via environment variable exposes it in `docker inspect <container>`, in `/proc/<pid>/environ` of every process inside the container, and to any binary Claude spawns. Prefer `claude login` inside the container on first use — credentials are then stored in the mounted `~/.claude/` directory and persist across sessions. Reserve the env-var path for non-interactive or scripted runs where browser-based login is not possible.

## Debugger

Per-language debugger setup (Delve port, IDE config, helper scripts) lives in [`docs/debugger-setup.md`](docs/debugger-setup.md).

## Opting out of helper scripts

Sourcing `shell/devenv.sh` also auto-sources every file under `scripts/` (e.g. `devenv-vscode-debug-golang`). To skip them, set `DEVENV_SKIP_EXTRAS=1` before sourcing:

```bash
DEVENV_SKIP_EXTRAS=1 source /path/to/this/repo/shell/devenv.sh
```

## Adding a New Language or Addon

The argument to `devenv` follows the convention `<lang>[-<addon>]` (e.g. `golang`, `golang-claude`). The Compose layer stacks files instead of duplicating them.

### Add a new language `<lang>`

1. Create `compose/<lang>.yml` with only language-specific bits (image overrides, caches, debugger port, extra caps, etc.). Service name must be `devenv`.
2. Build a `devenv-image-<lang>` image (Dockerfile under `images/<lang>/`).
3. `devenv <lang>` will stack `compose/base.yml` + `compose/<lang>.yml`.

### Add a new addon `<addon>` (e.g. `claude`, `codex`, ...)

1. Create `compose/<addon>.yml` with only addon-specific bits (config mounts, env vars, etc.). Service name must be `devenv`. The addon name must not collide with any language name.
2. Build a `devenv-image-<lang>-<addon>` image that extends `devenv-image-<lang>` with the addon installed.
3. `devenv <lang>-<addon>` will stack `compose/base.yml` + `compose/<lang>.yml` + `compose/<addon>.yml`.

### Optional pieces

- `compose/<lang>-<addon>.yml` — combo-specific overrides; sourced only when present.
- `shell/lib/<name>.sh` defining `_devenv_lib_<name>_hook` — for shell-side prep (cache dirs, first-run prompts). The hook is discovered automatically, receives `(language, project, version)`, and may write to any `_DEVENV_PREP_*` global. Hooks self-gate on the language string. See `shell/lib/golang.sh` (cache dir creation), `shell/lib/python.sh` (uv cache dir creation), and `shell/lib/claude.sh` (interactive config setup) for reference implementations.
