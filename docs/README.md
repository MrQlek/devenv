# docs

Reference documentation for Docker Dev Env. The project [README](../README.md) is the entry point; everything below goes deeper.

## User docs

- **[commands.md](commands.md)** — `devenv`, `devenv-connect`, `devenv-exec`, `devenv-inspect` reference.
- **[shell-integration.md](shell-integration.md)** — sourcing `shell/devenv.sh`, tab completion, optional helpers.
- **[building-images.md](building-images.md)** — Makefile targets, tag namespaces, the Claude SHA known issue.
- **[caches.md](caches.md)** — host cache layout under `~/.devenv/`, what persists where.
- **[secrets.md](secrets.md)** — hiding host files from the container via `.devenv_exclude/`.
- **[claude-code.md](claude-code.md)** — Claude Code integration: config mounts, scope prompt, API key security.
- **[debugger-setup.md](debugger-setup.md)** — per-language remote debugging from VS Code.

## Per-language

- **[languages/golang.md](languages/golang.md)** — Go-specific image contents, caches, ports.
- **[languages/python.md](languages/python.md)** — Python-specific image contents, caches, linting/type checking, `uv tool install` persistence.
- **[languages/typescript.md](languages/typescript.md)** — TypeScript/Node-specific image contents, Expo, `vsce`.

## Contributor docs

- **[adding-a-language.md](adding-a-language.md)** — adding a new language or addon, hook system, worked example.
