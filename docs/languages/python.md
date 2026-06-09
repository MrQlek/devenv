# Python

Image: `devenv-image-python` (or `devenv-image-python-claude` with Claude Code CLI preinstalled).

## What's in the image

- Python 3.14 (pinned by digest in `images/python/Dockerfile`)
- `uv` for project / dependency / tool management
- `debugpy`, `ruff`, `mypy` installed into the system Python — always available regardless of the active project venv
- `fzf`, `ripgrep`, `fd` (aliased from `fdfind`), `jq`, `vim`, `git`, `make`

## Caches

Persisted on the host under `~/.devenv/`, keyed by image version. Full table in [../caches.md](../caches.md).

- `~/.devenv/uv-cache/<version>/` → `~/.cache/uv` (download cache)
- `~/.devenv/uv-share/<version>/` → `~/.local/share/uv` (`uv tool install` environments)
- `~/.devenv/uv-bin/<version>/` → `~/.uv-tools/bin` (uv tool shims, on `PATH`)

The cache directories are auto-created on first run by `shell/lib/python.sh`.

### Project venv

Per-project packages (`.venv/`) are created by `uv` inside the workspace directory and persist via the host bind mount. They are **not** under `~/.devenv/`. This keeps the venv tied to the project tree and its branch state.

## Ports

- `5678` → debugpy (bound to `127.0.0.1`, declared in `compose/python.yml`)

## Running

```bash
devenv python dev
devenv python-claude dev
```

For the Claude variant, see [../claude-code.md](../claude-code.md) for the first-run config scope prompt.

## Linting and type checking

`ruff` and `mypy` are preinstalled in the system Python, so they're available without adding them to any project:

```bash
# Lint and format
ruff check .
ruff format .

# Type checking
mypy .
```

Both read their configuration from `pyproject.toml` or their own config files when present in the project.

To run them through the project's own Python (picking up project-specific deps and config):

```bash
uv run ruff check .
uv run mypy .
```

## `uv tool install` persistence

Tool environments installed with `uv tool install <name>` live under `~/.local/share/uv/` (the `uv-share` cache) and their shims live under `~/.uv-tools/bin/` (the `uv-bin` cache). Both directories are host-mounted, so tools survive container restarts.

If a shim goes missing after a restart (e.g. the `uv-bin` cache was deleted), re-run `uv tool install <name>` — the cached environment is reused, only the shim is regenerated.

## Debugging

See [../debugger-setup.md#python-python](../debugger-setup.md#python-python) for the full `debugpy` / VS Code attach flow and the `py-debug` / `py-debug-uv` aliases.

## Related

- [../commands.md](../commands.md) — `devenv` invocation and arguments.
- [../building-images.md](../building-images.md) — building `devenv-image-python` and `devenv-image-python-claude`.
