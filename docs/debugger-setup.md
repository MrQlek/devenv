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

---

## TypeScript / Node (`typescript`)

Covers both VSCode extension development and Expo mobile apps. Port `9229` (Node inspector) is published on `127.0.0.1`; port `8081` (Metro bundler) is published on `0.0.0.0` so a phone on the same Wi-Fi can reach it (declared in `compose/typescript.yml`).

### Inside the container — debugging Node / TS code

Three convenience aliases are available:

```bash
# TypeScript: tsc compile + node debug on the emitted JS (recommended)
ts-debug dist/app.js

# Plain JavaScript
node-debug app.js

# TypeScript via tsx — fast, but see "tsx caveat" below
tsx-debug app.ts

# Full form for custom options
node --inspect-brk=0.0.0.0:9229 <file>
```

Each prints `Debugger listening on ws://0.0.0.0:9229/...` and blocks until VS Code attaches.

`ts-debug` is just `tsc && node --inspect-brk=0.0.0.0:9229`, so it requires a `tsconfig.json` that emits to a known output path. A minimal one:

```json
{
  "compilerOptions": {
    "target": "es2022",
    "module": "commonjs",
    "sourceMap": true,
    "outDir": "dist"
  },
  "include": ["*.ts"]
}
```

The `sourceMap` flag is what lets VS Code show your `.ts` source while stepping through the compiled `.js`.

#### tsx caveat

`tsx` runs TypeScript transpilation in a Node worker thread that blocks on `Atomics.wait`. With `--inspect-brk` (which `tsx-debug` uses), the VS Code debugger usually opens paused inside that worker's wait loop, and pressing **Continue** on the worker thread is a no-op — the main thread also has to be resumed. To debug with `tsx-debug` you must open the **Call Stack** panel, select the **main** thread, then resume. For most workflows, `ts-debug` is simpler and more predictable.

### Inside the container — Expo (phone on LAN)

`npx create-expo-app my-app && cd my-app && npx expo start --lan` runs Metro on `8081`. Because the container publishes `8081` on `0.0.0.0`, the Expo Go app on your phone can scan the QR code and connect — make sure your phone is on the same Wi-Fi as your dev machine.

For native builds and store submissions, `eas-cli` is preinstalled. Auth tokens live in `~/.expo/state.json` and persist via the `expo` volume mount.

### Inside the container — VSCode extensions

`vsce` (the official VSCode extension packager) is preinstalled:

```bash
vsce package        # produces .vsix
vsce publish        # publish to the Marketplace
```

Scaffold a new extension per-project with `npx --package yo --package generator-code -- yo code`.

### VS Code (host → container)

Sourcing `shell/devenv.sh` defines `devenv-vscode-debug-typescript` (from `scripts/vscode-debug-typescript.sh`). Run it on the host, in the directory you pass to `devenv`:

```bash
devenv-vscode-debug-typescript          # writes .vscode/launch.json
devenv-vscode-debug-typescript --force  # overwrite an existing one
```

The generated `launch.json` attaches the VS Code Node debugger to the inspector on `127.0.0.1:9229` and uses `localRoot` / `remoteRoot` to map `${workspaceFolder}` on the host to `/workspace` inside the container.

End-to-end (Node / TS script):

1. Host: `devenv-vscode-debug-typescript` (once per project).
2. Host: `devenv typescript dev`.
3. Container: `cd /workspace/<your-project> && ts-debug dist/index.js` (run `tsc --init` once if you don't have a `tsconfig.json` yet).
4. VS Code: open the same directory on the host, set a breakpoint, F5 → **Attach to Node in devenv**.

### Troubleshooting

| Symptom | Likely cause |
|---|---|
| `ECONNREFUSED` on attach | `ts-debug` / `node-debug` / `tsx-debug` not running, or container started without the `9229` port mapping (`docker port <container>` should list it). |
| `tsx-debug` debugger pauses on `Atomics.wait` and Continue does nothing | tsx's transpile worker — open the **Call Stack** panel, select the **main** thread, then F5. Or just use `ts-debug`. |
| Breakpoints stay hollow / "unverified" | `localRoot` / `remoteRoot` mismatch — your host workspace folder isn't what was mounted to `/workspace`. Edit `launch.json`. |
| Phone can't connect to Metro / "Network response timed out" | Phone is on a different network than your dev machine, or the host firewall is blocking port `8081`. Verify both are on the same Wi-Fi and `docker port <container>` lists `0.0.0.0:8081`. |
| `vsce` complains about missing `package.json` fields | Run `vsce ls` to see what's missing; the VSCode extension manifest requires `publisher`, `engines.vscode`, and a few others before `vsce package` will succeed. |
