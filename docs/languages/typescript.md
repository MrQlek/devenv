# TypeScript / Node

Image: `devenv-image-typescript` (or `devenv-image-typescript-claude` with Claude Code CLI preinstalled). Covers both **VS Code extension development** and **Expo mobile apps**.

## What's in the image

- Node 24 LTS (pinned by digest in `images/typescript/Dockerfile`)
- `typescript`, `tsx`
- `@vscode/vsce` — official VS Code extension packager
- `eas-cli` — Expo Application Services CLI
- `fzf`, `ripgrep`, `fd` (aliased from `fdfind`), `jq`, `vim`, `git`, `make`

## Caches

Persisted on the host under `~/.devenv/`, keyed by image version. Full table in [../caches.md](../caches.md).

- `~/.devenv/npm-cache/<version>/` → `~/.npm` (npm download cache)
- `~/.devenv/expo/<version>/` → `~/.expo` (Expo / EAS state, including auth tokens)

The cache directories are auto-created on first run by `shell/lib/typescript.sh`.

### Project `node_modules`

Per-project `node_modules/` lives inside the workspace and persists via the host bind mount, not under `~/.devenv/`. This keeps dependencies tied to the project tree and its branch state.

## Ports

- `9229` → Node inspector (bound to `127.0.0.1`, for debuggers)
- `8081` → Metro bundler (bound to `0.0.0.0`, so a phone on the same Wi-Fi can connect)

Both declared in `compose/typescript.yml`. The `0.0.0.0` binding on `8081` is deliberate — Expo Go on a phone needs to reach Metro across the LAN.

## Running

```bash
devenv typescript dev
devenv typescript-claude dev
```

For the Claude variant, see [../claude-code.md](../claude-code.md) for the first-run config scope prompt.

## Expo (phone on LAN)

```bash
npx create-expo-app my-app
cd my-app
REACT_NATIVE_PACKAGER_HOSTNAME=<host-ip-address> npx expo start --lan
```

Metro runs on port `8081`. Because the container publishes that port on `0.0.0.0`, the Expo Go app on your phone can scan the QR code and connect — make sure your phone is on the same Wi-Fi as your dev machine.

For native builds and store submissions, `eas-cli` is preinstalled:

```bash
eas login
eas build
eas submit
```

Auth tokens live in `~/.expo/state.json`, persisted via the `expo` cache mount above, so you stay logged in across container restarts.

## VS Code extensions

`vsce` is preinstalled:

```bash
vsce package        # produces .vsix
vsce publish        # publish to the Marketplace
```

Scaffold a new extension per-project with `npx --package yo --package generator-code -- yo code`.

## Debugging

See [../debugger-setup.md#typescript--node-typescript](../debugger-setup.md#typescript--node-typescript) for the full Node inspector / VS Code attach flow and the `ts-debug` / `node-debug` / `tsx-debug` aliases.

## Related

- [../commands.md](../commands.md) — `devenv` invocation and arguments.
- [../building-images.md](../building-images.md) — building `devenv-image-typescript` and `devenv-image-typescript-claude`.
