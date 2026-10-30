# Adding a new language or addon

The argument to `devenv` follows the convention `<lang>[-<addon>]` (e.g. `golang`, `golang-claude`). The compose layer stacks files instead of duplicating them.

## Mental model

For a given invocation `devenv <lang>` or `devenv <lang>-<addon>`, the helper resolves and stacks:

1. `compose/base.yml` — image, mounts, security, resource limits. Always sourced.
2. `compose/<lang>.yml` — language-specific bits (ports, language cache volumes).
3. `compose/<addon>.yml` — addon-specific bits (only when an addon is requested).
4. `compose/<lang>-<addon>.yml` — combo-specific overrides (only if the file exists).

Plus an optional **hook** from `shell/lib/`, which runs host-side _before_ the container launches and can prepare directories, prompt the user, etc. See "Hook system" below.

The image to run is derived from the language string: `devenv-image-<lang>` or `devenv-image-<lang>-<addon>`. It must exist locally — there is no registry fallback.

## Add a new language `<lang>`

1. Create `compose/<lang>.yml` with only language-specific bits (image overrides, caches, debugger port, extra caps, etc.). Service name must be `devenv`.
2. Build a `devenv-image-<lang>` image (Dockerfile under `images/<lang>/`). The image must declare `ARG USER_ID` / `ARG GROUP_ID` and create a `devuser` user matching those — see the existing Dockerfiles for the pattern.
3. Add Makefile targets `build-<lang>` (tagged) and `build-<lang>-dev` (untagged), mirroring `build-golang` / `build-golang-dev`. If the image needs to `COPY` something from outside `images/<lang>/` (e.g. an installer script under `installers/`), build with the repo root as context instead — see `build-hugo` / `build-hugo-dev` (and `build-manim` / `build-manim-dev`), which use `-f images/<lang>/Dockerfile .` for exactly this reason.
4. (Optional) Create `shell/lib/<lang>.sh` defining `_devenv_lib_<lang>_hook` — useful for auto-creating cache directories. See the worked example below.
5. (Optional) Add a per-language page under `docs/languages/<lang>.md` and a debugger section to `docs/debugger-setup.md`.

`devenv <lang>` will then stack `compose/base.yml` + `compose/<lang>.yml`.

## Add a new addon `<addon>` (e.g. `claude`, `codex`)

1. Create `compose/<addon>.yml` with only addon-specific bits (config mounts, env vars). Service name must be `devenv`. The addon name must not collide with any language name.
2. Build a `devenv-image-<lang>-<addon>` image that extends `devenv-image-<lang>` with the addon installed. See `images/golang-claude/Dockerfile` for the `ARG BASE_VERSION` pattern.
3. Add Makefile targets `build-<lang>-<addon>` and `build-<lang>-<addon>-dev` for every language you want the addon available on.
4. (Optional) `shell/lib/<addon>.sh` with a hook gated on `[[ "$language" == *-<addon> ]]`.

`devenv <lang>-<addon>` will then stack `compose/base.yml` + `compose/<lang>.yml` + `compose/<addon>.yml` (plus the optional combo override).

## Optional pieces

- `compose/<lang>-<addon>.yml` — combo-specific overrides; sourced only when present.
- `shell/lib/<name>.sh` — host-side preparation hook (see below).

---

## Hook system (`shell/lib/`)

Each `shell/lib/*.sh` file defines a function named `_devenv_lib_<name>_hook`. The helper discovers these by name pattern, sources them fresh on every `devenv` invocation, calls every matching hook, and then unloads them. There is no central registration.

### Hook contract

```bash
_devenv_lib_<name>_hook() {
    local language=$1   # full language string, e.g. "python-claude"
    local project=$2    # project slug, derived from cwd
    local version=$3    # image version (the second arg to `devenv`)

    # Self-gate: skip work if this hook doesn't apply to the requested language.
    [[ "$language" == python* ]] || return 0

    # ... do prep work ...
}
```

- **Self-gating:** Every hook is called for every invocation. A hook must inspect `$language` and return early if it doesn't apply.
- **Outputs:** Hooks may write to any `_DEVENV_PREP_*` global. The helper reads those globals after running all hooks. Currently used: `_DEVENV_PREP_CLAUDE_DIR`, `_DEVENV_PREP_CLAUDE_FILE` (set by `shell/lib/claude.sh`).
- **Side effects are fine:** Creating cache directories, prompting the user, generating config — anything you'd otherwise do by hand before `docker compose run`.
- **Exit nonzero to abort:** A nonzero return from any hook aborts the `devenv` call before the container is launched.

### Reference implementations

- `shell/lib/golang.sh` — creates `~/.devenv/go-mod/<version>/` and `~/.devenv/go-cache/<version>/`. Minimal, no globals written.
- `shell/lib/python.sh` — same pattern, for the three uv-related cache dirs.
- `shell/lib/typescript.sh` — same pattern, for the npm and Expo cache dirs.
- `shell/lib/claude.sh` — interactive first-run prompt for config scope, writes `_DEVENV_PREP_CLAUDE_DIR` / `_DEVENV_PREP_CLAUDE_FILE` which `compose/claude.yml` substitutes into its mount entries.

---

## Worked example: adding Python

When Python was added, four pieces landed together:

1. **Compose file** — `compose/python.yml`:

   ```yaml
   services:
     devenv:
       ports:
         - "127.0.0.1:5678:5678"      # debugpy
       volumes:
         - ${_DEVENV_USER_HOME}/.devenv/uv-cache/${IMAGE_VERSION:-dev}:/home/devuser/.cache/uv
         - ${_DEVENV_USER_HOME}/.devenv/uv-share/${IMAGE_VERSION:-dev}:/home/devuser/.local/share/uv
         - ${_DEVENV_USER_HOME}/.devenv/uv-bin/${IMAGE_VERSION:-dev}:/home/devuser/.uv-tools/bin
   ```

   Only the Python-specific bits — everything else (workspace mount, security, tmpfs) comes from `compose/base.yml`.

2. **Image** — `images/python/Dockerfile`, built into `devenv-image-python:<tag>`. Standard pattern: pinned base by digest, `ARG USER_ID`/`GROUP_ID`, create `devuser`, install dev tools and aliases.

3. **Make targets** — `build-python`, `build-python-dev` in the Makefile.

4. **Hook** — `shell/lib/python.sh`:

   ```bash
   _devenv_lib_python_hook() {
       local language=$1
       local project=$2
       local version=$3
       [[ "$language" == python* ]] || return 0
       mkdir -p "$_DEVENV_USER_HOME/.devenv/uv-cache/$version"
       mkdir -p "$_DEVENV_USER_HOME/.devenv/uv-share/$version"
       mkdir -p "$_DEVENV_USER_HOME/.devenv/uv-bin/$version"
   }
   ```

   The `[[ "$language" == python* ]]` gate makes the hook also fire for `python-claude` (and any future `python-<addon>`), since the cache dirs are needed regardless of addon.

After those four pieces, `devenv python dev` works end-to-end and the language shows up in tab completion automatically (because `docker images | grep devenv-image-python` now returns a match).

To add the Claude variant on top, four more pieces landed: `images/python-claude/Dockerfile` extending the base, `build-python-claude` / `-dev` Makefile targets, and an `compose/claude.yml` entry (the addon compose file is already shared with `golang-claude` — no per-language work needed).

## Related

- [shell-integration.md](shell-integration.md) — how `shell/devenv.sh` discovers and runs hooks.
- [building-images.md](building-images.md) — Makefile conventions for the new build targets.
