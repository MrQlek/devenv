# Hugo

Image: `devenv-image-hugo` (or `devenv-image-hugo-claude` with Claude Code CLI preinstalled). Built on top of the `golang` base image because Hugo Modules (`hugo mod`) shell out to `go mod` internally.

## What's in the image

- Hugo Extended (pinned in `installers/hugo/install.sh`) — the extended build is required for the SCSS pipelines most themes use
- Go toolchain (for Hugo Modules)
- `fzf`, `ripgrep`, `fd` (aliased from `fdfind`), `jq`, `vim`, `git`, `make`

## Caches

Persisted on the host under `~/.devenv/`, keyed by image version. Full table in [../caches.md](../caches.md).

- `~/.devenv/hugo-mod/<version>/` → `~/go/pkg/mod` (Go module cache, backs Hugo Modules)
- `~/.devenv/hugo-cache/<version>/` → `~/.cache/hugo` (`HUGO_CACHEDIR` — resource/image-processing cache and cached remote modules)

The cache directories are auto-created on first run by `shell/lib/hugo.sh`.

## Ports

- `1313` → `hugo server` live-reload dev server (bound to `127.0.0.1`)

Declared in `compose/hugo.yml`.

## Running

```bash
devenv hugo dev
devenv hugo-claude dev
```

For the Claude variant, see [../claude-code.md](../claude-code.md) for the first-run config scope prompt.

## Typical workflow

```bash
hugo new site my-site
cd my-site
hugo mod init github.com/you/my-site   # if using Hugo Modules for a theme
hugo server --bind 0.0.0.0             # -D to include drafts
```

`hugo server` binds to `1313` by default; pass `--bind 0.0.0.0` so it's reachable from outside the container (the port itself is already published to `127.0.0.1` only — see [../commands.md](../commands.md) if you need it reachable from other machines on the LAN).

## Debugging

Hugo is a static-site generator, not a long-running application — there's no remote debugger wired up for it (see [../debugger-setup.md](../debugger-setup.md)). Use `hugo server`'s live reload plus `hugo --verbose` / `--debug` for troubleshooting build errors.

## Related

- [../commands.md](../commands.md) — `devenv` invocation and arguments.
- [../building-images.md](../building-images.md) — building `devenv-image-hugo` and `devenv-image-hugo-claude`.
