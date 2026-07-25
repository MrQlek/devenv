# Debugger setup

Per-language remote-debugging setup for code running inside a devenv container. New languages should add a section here.

The general pattern is the same for all languages:

1. The container exposes a debugger port on `127.0.0.1` (so only the host can attach).
2. An in-container alias starts the debugger in "wait for client" mode.
3. A host-side script (`devenv-vscode-debug-<lang>`, defined in `scripts/`) writes a `.vscode/launch.json` that attaches to that port and maps `${workspaceFolder}` ↔ `/workspace`.

For VS Code's attach to actually pause inside your code, the host and container paths must match. The launch.json generators all use `substitutePath` / `pathMappings` / `localRoot+remoteRoot` (depending on language) to bridge that.

---

## Go (`golang`, `golang-claude`)

Delve is preinstalled and port `2345` is published on `127.0.0.1` (declared in `compose/golang.yml`). The `SYS_PTRACE` capability needed for `ptrace`-based debugging is added in `compose/base.yml`.

### Inside the container

A convenience alias starts Delve in headless mode:

```bash
dlv-debug   # = dlv debug --headless --listen=:2345 --api-version=2
```

Run it from the directory of the package you want to debug. It prints `API server listening at: [::]:2345` and blocks until a debugger attaches.

### VS Code (host → container)

Sourcing `shell/devenv.sh` defines `devenv-vscode-debug-golang` (from `scripts/vscode-debug.sh`). Run it on the host, in the directory you pass to `devenv`:

```bash
devenv-vscode-debug-golang          # writes .vscode/launch.json
devenv-vscode-debug-golang --force  # overwrite an existing one
```

The generated `launch.json` attaches to Delve on `127.0.0.1:2345` and uses `substitutePath` to map `${workspaceFolder}` on the host to `/workspace` inside the container, so VS Code's breakpoints line up with the paths Delve reports.

### End-to-end

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

## Python (`python`, `python-claude`)

`debugpy` is preinstalled in the system Python (available regardless of the active project venv). Port `5678` is published on `127.0.0.1` (declared in `compose/python.yml`).

For linting, type checking, and the broader Python workflow, see [languages/python.md](languages/python.md).

### Inside the container

Two convenience aliases are available:

```bash
# Uses system Python — always works, ignores project venv
py-debug app.py

# Uses project's uv venv — respects project dependencies (recommended)
py-debug-uv app.py

# Full form for custom options
uv run --with debugpy python -m debugpy --listen 0.0.0.0:5678 --wait-for-client app.py
```

debugpy prints `Waiting for client to connect...` and blocks until VS Code attaches.

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

### End-to-end

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
| `uv tool install` binary missing after container restart | See the persistence note in [languages/python.md](languages/python.md#uv-tool-install-persistence). |

---

## TypeScript / Node (`typescript`, `typescript-claude`)

Port `9229` (Node inspector) is published on `127.0.0.1` (declared in `compose/typescript.yml`).

For the broader TypeScript workflow — Expo, `vsce`, port `8081` semantics — see [languages/typescript.md](languages/typescript.md).

### Inside the container

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

### VS Code (host → container)

Sourcing `shell/devenv.sh` defines `devenv-vscode-debug-typescript` (from `scripts/vscode-debug-typescript.sh`). Run it on the host, in the directory you pass to `devenv`:

```bash
devenv-vscode-debug-typescript          # writes .vscode/launch.json
devenv-vscode-debug-typescript --force  # overwrite an existing one
```

The generated `launch.json` attaches the VS Code Node debugger to the inspector on `127.0.0.1:9229` and uses `localRoot` / `remoteRoot` to map `${workspaceFolder}` on the host to `/workspace` inside the container.

### End-to-end (Node / TS script)

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

---

## Hugo (`hugo`, `hugo-claude`)

Hugo is a static-site generator, not a long-running process with a debuggable runtime — there's no remote debugger wired up for it. `hugo server` (port `1313`, published on `127.0.0.1`, declared in `compose/hugo.yml`) gives live reload instead. See [languages/hugo.md](languages/hugo.md) for the full workflow.
