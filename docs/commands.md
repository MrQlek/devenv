# Commands

Sourcing `shell/devenv.sh` defines four commands. See [shell-integration.md](shell-integration.md) for how to wire it into your shell.

All four take `[language]` as their first argument. The language string follows the convention `<lang>[-<addon>]` — for example `golang`, `golang-claude`, `python-claude`. When omitted, it defaults to `golang`.

---

## `devenv [language] [version] [ports] [public-ports]`

Starts a new container with your current directory bind-mounted at `/workspace`.

| Argument | Default | Description |
|---|---|---|
| `language` | `golang` | Language (and optional addon), e.g. `python`, `golang-claude` |
| `version` | `dev` | Image tag — must correspond to an existing local image |
| `ports` | _none_ | Comma-separated ports bound to `127.0.0.1` (localhost only) |
| `public-ports` | _none_ | Comma-separated ports bound to `0.0.0.0` (all interfaces) |

Use `ports` for normal local development. Use `public-ports` only when the port needs to be reachable from other machines on the network — for example, an Expo dev server that a phone on the same Wi-Fi connects to.

### Examples

```bash
# Default: golang dev image
devenv

# Specific language and image tag
devenv python dev
devenv golang-claude v1.2.0

# Localhost-only ports
devenv golang-claude dev 3000,9090
devenv python dev 8000,5678

# All-interfaces ports
devenv golang-claude dev "" 8080,8443

# Mix: some localhost, some public
devenv golang-claude dev 3000 8080
```

### What gets mounted

- Current working directory → `/workspace`
- `.git/` (if present, read-only) → `/workspace/.git`
- `/workspace/.devenv_exclude` → in-memory tmpfs (see [secrets.md](secrets.md))
- Language-specific caches under `~/.devenv/` — see [caches.md](caches.md)
- For `*-claude` variants: Claude config — see [claude-code.md](claude-code.md)

---

## `devenv-connect [language]`

Opens an additional bash shell in a container that's already running.

```bash
devenv-connect golang-claude
devenv-connect python
```

Useful for running side commands (tests, debuggers, REPLs) without losing the original session.

---

## `devenv-exec [language] <command> [args...]`

Runs a single command inside a running container and exits.

```bash
devenv-exec golang go test ./...
devenv-exec golang-claude claude --version
devenv-exec python uv run pytest
```

Equivalent to `docker exec` against the project's container. The container must already be running (start it with `devenv` first).

---

## `devenv-inspect [language] [version] [ports] [public-ports] [--raw]`

Prints the merged Docker Compose config plus the runtime flags that would be passed to `docker compose run`. Use it to verify what `devenv` would actually do without launching a container.

```bash
devenv-inspect golang dev
devenv-inspect python dev
devenv-inspect golang-claude dev 3000 --raw   # keep ${VAR} placeholders
```

The `--raw` flag passes `--no-interpolate` to `docker compose config`, which leaves `${VAR}` references unresolved. Useful when debugging which compose file contributed which line.

---

## Tab completion

Completion for `language` and `version` arguments is enabled automatically on bash and zsh. Candidates are derived from your locally-built `devenv-image-*` images (via `docker images`), so only buildable/runnable combos are offered.

This means tab completion requires the Docker daemon to be accessible — if `docker images` fails, completion silently returns nothing. See [shell-integration.md](shell-integration.md).

For `devenv-connect` and `devenv-exec`, completion lists the languages of containers currently running for the current project directory.
