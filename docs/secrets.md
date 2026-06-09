# Hiding host files from the container

The container always has `/workspace/.devenv_exclude` mounted as an in-memory tmpfs (declared in `compose/base.yml`). The tmpfs is empty from the container's point of view — it shadows anything the host has at that path under your workspace.

Use it to keep host-side files reachable from your shell but invisible to anything inside the container (including coding agents like Claude).

## Layout

Place anything you want hidden under `.devenv_exclude/` in your project root:

```
.devenv_exclude/
├── aws/credentials
├── env-prod
└── ssh/id_rsa
```

From the host, these files exist normally. From inside the container, `ls /workspace/.devenv_exclude` shows an empty tmpfs.

Subdirectories are fine — anything below `.devenv_exclude/` is hidden.

## Masking a file outside `.devenv_exclude/`

Only the `.devenv_exclude/` path itself is shadowed. To hide something at a different location (e.g. a `.env` at the workspace root), move or symlink it under `.devenv_exclude/`:

```bash
mv .env .devenv_exclude/env
ln -s .devenv_exclude/env .env   # optional: keep host tooling that expects ./.env happy
```

The symlink itself is visible inside the container, but it points into the tmpfs and resolves to nothing.

## Don't commit it

Add `.devenv_exclude/` to your `.gitignore` — the contents are by definition things that should not be tracked.

## Threat model

`.devenv_exclude/` protects against **anything running inside the container reading the listed files**. That includes the shell, your build tools, debuggers, and any coding agent.

It does **not** protect against:

- **A malicious image.** If you `docker pull` and `devenv` into an image you don't trust, the operator controls the runtime. The mount semantics are still in effect, but the operator can ignore them and exfiltrate other paths (your workspace, environment variables, network).
- **A malicious process you run yourself.** If you `curl | bash` something hostile inside the container, it can read your bind-mounted workspace and your home cache directories under `~/.devenv/`. Those are mounted normally.
- **Host-level access.** Anyone on the host (root, other users with permission) can read `.devenv_exclude/` directly — it's a regular host directory.

For host-side defense in depth, also run [Docker in rootless mode](https://docs.docker.com/engine/security/rootless/) so a container break-out does not yield host root.

## Related

- [commands.md](commands.md) — what else gets mounted (workspace, caches, `.git`).
- [claude-code.md](claude-code.md) — Claude credentials and config mount, separate from `.devenv_exclude/`.
