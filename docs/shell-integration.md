# Shell integration

The `devenv` / `devenv-connect` / `devenv-exec` / `devenv-inspect` commands are bash/zsh functions defined in `shell/devenv.sh`. Source it from your shell rc file:

```bash
# ~/.bashrc or ~/.zshrc
source /path/to/this/repo/shell/devenv.sh
```

After that the commands are available in every new shell.

## Requirements

- `docker` and the `docker compose` plugin on `PATH`. On source, `devenv.sh` prints a warning if `docker compose version` fails.
- Docker accessible to your user without `sudo`. If `docker info` fails, the helper functions error out with a pointer to [rootless Docker setup](https://docs.docker.com/engine/security/rootless/).

## Tab completion

Completion is registered automatically for bash and zsh (zsh users get it via `bashcompinit`, sourced from `shell/completion.sh`).

- For `devenv` and `devenv-inspect`: the language and version completions are derived from `docker images` output, filtered to repositories matching `devenv-image-*`. Only images you have built locally are offered, so you can't accidentally tab-complete a language you haven't set up yet.
- For `devenv-connect` and `devenv-exec`: completion lists the languages of containers currently running for the current project directory.

**Tab completion calls the Docker CLI**, so it requires the Docker daemon to be running and accessible. If `docker images` errors out (daemon down, permissions issue), completion silently returns no candidates — that's not a bug in the completion script, it's the daemon.

## Helper scripts under `scripts/`

Sourcing `shell/devenv.sh` also auto-sources every `*.sh` file under `scripts/`. These define optional user-facing helpers — currently the three `devenv-vscode-debug-*` commands that generate VS Code `launch.json` files for in-container debugging (see [debugger-setup.md](debugger-setup.md)).

To skip auto-sourcing the `scripts/` helpers, set `DEVENV_SKIP_EXTRAS=1` _before_ sourcing `devenv.sh`:

```bash
DEVENV_SKIP_EXTRAS=1 source /path/to/this/repo/shell/devenv.sh
```

The core `devenv` commands are unaffected — only the optional extras are skipped.

## Internals (`shell/lib/`)

`shell/lib/*.sh` define per-language hooks (`_devenv_lib_<name>_hook`) that prepare host directories before launching a container (e.g. creating cache dirs, prompting for Claude config scope). These are sourced fresh on every `devenv` invocation and unloaded immediately after — they're not part of the public surface.

If you're extending the system with a new language or addon, see [adding-a-language.md](adding-a-language.md).
