# Go

Image: `devenv-image-golang` (or `devenv-image-golang-claude` with Claude Code CLI preinstalled).

## What's in the image

- Go 1.26 (pinned by digest in `images/golang/Dockerfile`)
- `gopls`, `delve`, `air`
- `fzf`, `ripgrep`, `fd` (aliased from `fdfind`), `jq`, `vim`, `git`, `make`
- C toolchain and the X11/OpenGL headers needed for cgo-heavy projects (Fyne, etc.)

## Caches

Persisted on the host under `~/.devenv/`, keyed by image version. Full table in [../caches.md](../caches.md).

- `~/.devenv/go-mod/<version>/` → `$GOPATH/pkg/mod` (module cache)
- `~/.devenv/go-cache/<version>/` → `~/.cache/go-build` (build cache)

The cache directories are auto-created on first run by `shell/lib/golang.sh`.

## Ports

- `2345` → Delve (bound to `127.0.0.1`, declared in `compose/golang.yml`)

## Running

```bash
devenv golang dev
devenv golang-claude dev
```

For the Claude variant, see [../claude-code.md](../claude-code.md) for the first-run config scope prompt.

## Debugging

See [../debugger-setup.md#go-golang-golang-claude](../debugger-setup.md#go-golang-golang-claude) for the full Delve / VS Code attach flow.

## Related

- [../commands.md](../commands.md) — `devenv` invocation and arguments.
- [../building-images.md](../building-images.md) — building `devenv-image-golang` and `devenv-image-golang-claude`.
