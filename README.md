# Dev Env

Reproducible, containerized development environments for Go, Python, TypeScript, Hugo, .NET, and Manim, with optional Claude Code integration.

Each language gets its own image with the toolchain, debugger, and CLI utilities preinstalled. Your current directory bind-mounts at `/workspace`, the container runs as a non-root `devuser` matching your host UID/GID (no `chown` dance on bind-mounted files), and per-language caches are persisted on the host under `~/.devenv/` so you don't re-download modules on every restart.

Developed with Claude Code.

## Quick start

```bash
# 1. Clone
git clone https://github.com/MrQlek/devenv ~/code/devenv
cd ~/code/devenv

# 2. Build the image for the language you want
make build-golang-dev          # or build-python-dev / build-typescript-dev / build-manim-dev …

# 3. Source the shell helpers (add to your ~/.bashrc or ~/.zshrc)
source ~/code/devenv/shell/devenv.sh

# 4. Run a dev container in any project
cd ~/code/myproject
devenv golang dev              # your cwd is mounted at /workspace
```

For the Claude variants (`golang-claude`, `python-claude`, `typescript-claude`, `hugo-claude`, `dotnet-claude`, `manim-claude`), build the base image first, then the Claude image on top — see [docs/building-images.md](docs/building-images.md).

## Available environments

| Image | What you get |
|---|---|
| `devenv-image-golang` | Go + `gopls`, `delve`, `air`, `fzf`, `ripgrep`, `fd`, `jq`, `vim` |
| `devenv-image-golang-claude` | …plus Claude Code CLI |
| `devenv-image-python` | Python 3.14 + `uv` + `debugpy` + `ruff` + `mypy` + dev tools |
| `devenv-image-python-claude` | …plus Claude Code CLI |
| `devenv-image-typescript` | Node 24 LTS + `typescript`, `tsx`, `@vscode/vsce`, `eas-cli` + dev tools |
| `devenv-image-typescript-claude` | …plus Claude Code CLI |
| `devenv-image-hugo` | Hugo Extended + Go toolchain (for Hugo Modules) + `fzf`, `ripgrep`, `fd`, `jq`, `vim` |
| `devenv-image-hugo-claude` | …plus Claude Code CLI |
| `devenv-image-dotnet` | .NET 10.0 SDK (for Avalonia / Photino GUI apps) + `fzf`, `ripgrep`, `fd`, `jq`, `vim` |
| `devenv-image-dotnet-claude` | …plus Claude Code CLI |
| `devenv-image-manim` | Python 3.14 + `uv` + `ffmpeg` + curated TeX Live + cairo/pango build deps for [Manim Community Edition](https://www.manim.community/); starter project via `manim-init` (manim itself is pinned per project by `uv`, not baked into the image) |
| `devenv-image-manim-claude` | …plus Claude Code CLI |

Twelve images in total — six languages × with/without Claude. Each is documented in [docs/languages/](docs/languages/).

## Versioning

Each image has its own git-tag namespace, and Claude variants are versioned independently from their base:

| Image | Tag namespace |
|---|---|
| `devenv-image-golang` | `golang/*` |
| `devenv-image-golang-claude` | `golang-claude/*` |
| `devenv-image-python` | `python/*` |
| `devenv-image-python-claude` | `python-claude/*` |
| `devenv-image-typescript` | `typescript/*` |
| `devenv-image-typescript-claude` | `typescript-claude/*` |
| `devenv-image-hugo` | `hugo/*` |
| `devenv-image-hugo-claude` | `hugo-claude/*` |
| `devenv-image-dotnet` | `dotnet/*` |
| `devenv-image-dotnet-claude` | `dotnet-claude/*` |
| `devenv-image-manim` | `manim/*` |
| `devenv-image-manim-claude` | `manim-claude/*` |

Tagged builds (e.g. `make build-golang`) require the matching tag on HEAD. For day-to-day work use `make build-<lang>-dev`, which produces `:dev` and skips the tag requirement. Full rules in [docs/building-images.md](docs/building-images.md).

## Core commands

After sourcing `shell/devenv.sh`:

- **`devenv [language] [version] [ports] [public-ports]`** — start a container with cwd mounted at `/workspace`. Defaults to `golang dev`. Add `--no-default-ports` to skip the language's built-in port mappings (debugger, dev server) so you can run several containers of the same language at once, e.g. `devenv python dev 8001 --no-default-ports`.
- **`devenv-connect [language]`** — open an additional shell in a running container.
- **`devenv-exec [language] <command> [args...]`** — run a one-off command in a running container.
- **`devenv-inspect [language] [version] …`** — print the merged compose config and runtime flags without launching.

Tab completion for these commands is enabled automatically on bash and zsh. It works by calling `docker images`, so **it requires the Docker daemon to be running** — completion returns nothing if the daemon is unreachable.

Full reference: [docs/commands.md](docs/commands.md).

## Hiding secrets from the container

`/workspace/.devenv_exclude` is mounted as an in-memory tmpfs inside the container. Anything you place under `.devenv_exclude/` on the host stays on the host — the container sees the directory as empty. Useful for API keys, SSH credentials, or anything else you don't want a coding agent to read.

Add `.devenv_exclude/` to your `.gitignore`. Full details and threat model in [docs/secrets.md](docs/secrets.md).

## Security

The container runs as non-root `devuser`, drops all capabilities except `SYS_PTRACE` (needed for debuggers), sets `no-new-privileges`, and has CPU/memory/pid limits applied. See `compose/base.yml`.

For defense in depth — especially when running coding agents that fetch and execute arbitrary code — **run the Docker daemon in [rootless mode](https://docs.docker.com/engine/security/rootless/)**. A container break-out under rootless Docker yields only your user's privileges, not root.

## Known issues

- **Claude image build fails on SHA mismatch.** The Claude Code install script's pinned SHA digest can go stale when upstream rotates the script, breaking the `*-claude` image builds. Workaround for now: manually update the digest in `installers/claude/` (and any matching `images/<lang>-claude/Dockerfile` pin). A proper fix is on the backlog. See [docs/building-images.md](docs/building-images.md#claude-variants).

## Documentation

- [docs/commands.md](docs/commands.md) — full command reference
- [docs/building-images.md](docs/building-images.md) — Makefile targets and tag rules
- [docs/shell-integration.md](docs/shell-integration.md) — sourcing the helpers, completion, opt-out
- [docs/caches.md](docs/caches.md) — host cache layout
- [docs/secrets.md](docs/secrets.md) — `.devenv_exclude/` and threat model
- [docs/claude-code.md](docs/claude-code.md) — Claude Code config mounts and API key security
- [docs/debugger-setup.md](docs/debugger-setup.md) — per-language remote debugging
- [docs/languages/](docs/languages/) — Go, Python, TypeScript, Hugo, .NET, Manim specifics
- [docs/adding-a-language.md](docs/adding-a-language.md) — extend the system with a new language or addon

## Requirements

- Docker with the Compose plugin (`docker compose`)
- GNU Make
- bash or zsh
