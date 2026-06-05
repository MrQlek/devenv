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
