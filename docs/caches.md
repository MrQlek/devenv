# Host caches

Per-language caches are persisted on the host under `~/.devenv/`, keyed by the image version. Reusing them across container restarts avoids re-downloading modules, wheels, or npm packages every session.

The version segment in each path is the image tag you invoked `devenv` with (`dev` by default), so different image versions keep separate caches and never collide.

## Layout

| Language | Host path | Container path | Purpose |
|---|---|---|---|
| Go | `~/.devenv/go-mod/<version>/` | `/home/devuser/go/pkg/mod` | Module cache |
| Go | `~/.devenv/go-cache/<version>/` | `/home/devuser/.cache/go-build` | Build cache |
| Python | `~/.devenv/uv-cache/<version>/` | `/home/devuser/.cache/uv` | uv download cache (wheels/sdists) |
| Python | `~/.devenv/uv-share/<version>/` | `/home/devuser/.local/share/uv` | `uv tool install` environments |
| Python | `~/.devenv/uv-bin/<version>/` | `/home/devuser/.uv-tools/bin` | uv tool shims (added to `PATH`) |
| TypeScript | `~/.devenv/npm-cache/<version>/` | `/home/devuser/.npm` | npm download cache |
| TypeScript | `~/.devenv/expo/<version>/` | `/home/devuser/.expo` | Expo / EAS state (auth tokens, etc.) |
| Hugo | `~/.devenv/hugo-mod/<version>/` | `/home/devuser/go/pkg/mod` | Go module cache (backs Hugo Modules) |
| Hugo | `~/.devenv/hugo-cache/<version>/` | `/home/devuser/.cache/hugo` | `HUGO_CACHEDIR` — resource/image-processing cache, cached remote modules |

Claude variants additionally use `~/.devenv/claude/` for configuration mounts — see [claude-code.md](claude-code.md).

## In-workspace state

A few things live inside your workspace rather than under `~/.devenv/`, so they persist via the host bind mount rather than a named cache:

- **Python `.venv/`** — the uv-managed project venv is created in your project directory and mounted with it.
- **TypeScript `node_modules/`** — per-project `node_modules` live in the workspace.

This keeps project dependencies tied to the project tree (and to its git/branch state), while the host caches above stay shared across projects.

## Reclaiming disk space

Each cache directory is plain files on the host — safe to delete when you no longer need a particular image version's cache:

```bash
rm -rf ~/.devenv/go-mod/<old-version> ~/.devenv/go-cache/<old-version>
rm -rf ~/.devenv/uv-cache/<old-version> ~/.devenv/uv-share/<old-version> ~/.devenv/uv-bin/<old-version>
rm -rf ~/.devenv/npm-cache/<old-version> ~/.devenv/expo/<old-version>
rm -rf ~/.devenv/hugo-mod/<old-version> ~/.devenv/hugo-cache/<old-version>
```

The cache directories are recreated automatically on the next `devenv` invocation for that version.
