# Debugger setup

Per-language remote-debugging setup for code running inside a devenv container. New languages should add a section here.

## Go (`golang`, `golang-claude`)

Delve is preinstalled and port `2345` is published on `127.0.0.1` (declared in `compose/golang.yml`). The `SYS_PTRACE` capability needed for `ptrace`-based debugging is added in `compose/base.yml`.

### Inside the container

A convenience alias starts delve in headless mode:

```bash
dlv-debug   # = dlv debug --headless --listen=:2345 --api-version=2
```

Run it from the directory of the package you want to debug. It will print `API server listening at: [::]:2345` and block until a debugger attaches.

### VS Code (host → container)

Sourcing `shell/devenv.sh` defines `devenv-vscode-debug-golang` (from `scripts/vscode-debug.sh`). Run it on the host, in the directory you pass to `devenv`:

```bash
devenv-vscode-debug-golang          # writes .vscode/launch.json
devenv-vscode-debug-golang --force  # overwrite an existing one
```

The generated `launch.json` attaches to delve on `127.0.0.1:2345` and uses `substitutePath` to map `${workspaceFolder}` on the host to `/workspace` inside the container, so VS Code's breakpoints line up with the paths delve reports.

End-to-end:

1. Host: `devenv-vscode-debug-golang` (once per project).
2. Host: `devenv golang dev` (or `golang-claude dev`).
3. Container: `cd /workspace/<your-package> && dlv-debug`.
4. VS Code: open the same directory on the host, set a breakpoint, F5 → **Attach to dlv in devenv**.

### Troubleshooting

| Symptom | Likely cause |
|---|---|
| `ECONNREFUSED` on attach | `dlv-debug` not running, or container started without the `2345` port mapping (`docker port <container>` should list it). |
| Breakpoints stay hollow / "unverified" | `substitutePath` mismatch — your host workspace folder isn't what was mounted to `/workspace`. Edit the `from` field in `launch.json`. |
| `could not attach to pid …: operation not permitted` | `SYS_PTRACE` not applied. `compose/base.yml` adds it; verify with `docker inspect`. |

---

## Python (`python`)

`debugpy`, `ruff`, and `mypy` are preinstalled in the system Python (available regardless of the active project venv). Port `5678` is published on `127.0.0.1` (declared in `compose/python.yml`).

### Inside the container — debugging

Two convenience aliases are available:

```bash
# Uses system Python — always works, ignores project venv
py-debug app.py

# Uses project's uv venv — respects project dependencies (recommended)
py-debug-uv app.py

# Full form for custom options
uv run --with debugpy python -m debugpy --listen 0.0.0.0:5678 --wait-for-client app.py
```

Debugpy prints `Waiting for client to connect...` and blocks until VS Code attaches.

### Inside the container — linting and type checking

```bash
# Lint and format
ruff check .
ruff format .

# Type checking
mypy .

# Run via uv (uses project's Python, picks up project config)
uv run ruff check .
uv run mypy .
```

`ruff` and `mypy` read their configuration from `pyproject.toml` or their own config files when present in the project.

### VS Code (host → container)

Sourcing `shell/devenv.sh` defines `devenv-vscode-debug-python` (from `scripts/vscode-debug-python.sh`). Run it on the host, in the directory you pass to `devenv`:

```bash
devenv-vscode-debug-python          # writes .vscode/launch.json
devenv-vscode-debug-python --force  # overwrite an existing one
```

The generated `launch.json` attaches to debugpy on `127.0.0.1:5678` and uses `pathMappings` to map `${workspaceFolder}` on the host to `/workspace` inside the container.

For the VS Code Python and Pylance extensions to resolve imports correctly, point them at the project's uv-managed interpreter. Add this to `.vscode/settings.json` in your project:

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
```

End-to-end:

1. Host: `devenv-vscode-debug-python` (once per project).
2. Host: `devenv python dev`.
3. Container: `uv init myapp && cd myapp && uv add flask`.
4. Container: `py-debug-uv app.py`.
5. VS Code: open the same directory on the host, set a breakpoint, F5 → **Attach to debugpy in devenv**.

### Troubleshooting

| Symptom | Likely cause |
|---|---|
| `ECONNREFUSED` on attach | `py-debug` / `py-debug-uv` not running, or container started without the `5678` port mapping (`docker port <container>` should list it). |
| Breakpoints stay hollow / "unverified" | `pathMappings` mismatch — your host workspace folder isn't what was mounted to `/workspace`. Edit the `localRoot` field in `launch.json`. |
| `ModuleNotFoundError: No module named 'debugpy'` with `py-debug-uv` | Use the full form `uv run --with debugpy python -m debugpy ...` to inject debugpy without adding it to the project. |
| VS Code can't resolve imports / red underlines | Set `python.defaultInterpreterPath` in `.vscode/settings.json` to point at `.venv/bin/python` (see above). |
| `uv tool install` binaries missing after container restart | Tool environments persist via the `uv-share` volume but shims in `~/.local/bin` are on the `uv-bin` volume — both should survive restarts. If a shim is missing, re-run `uv tool install <name>`. |
