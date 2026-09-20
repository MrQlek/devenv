# Building images

All images are built locally via `make` targets. There is no registry — images live only on the host that built them.

## Image inventory

| Image | Tag namespace | Built from |
|---|---|---|
| `devenv-image-golang` | `golang/*` | `images/golang/` |
| `devenv-image-golang-claude` | `golang-claude/*` | `images/golang-claude/` (extends `devenv-image-golang`) |
| `devenv-image-python` | `python/*` | `images/python/` |
| `devenv-image-python-claude` | `python-claude/*` | `images/python-claude/` (extends `devenv-image-python`) |
| `devenv-image-typescript` | `typescript/*` | `images/typescript/` |
| `devenv-image-typescript-claude` | `typescript-claude/*` | `images/typescript-claude/` (extends `devenv-image-typescript`) |
| `devenv-image-hugo` | `hugo/*` | `images/hugo/` (built with the repo root as context — see note below) |
| `devenv-image-hugo-claude` | `hugo-claude/*` | `images/hugo-claude/` (extends `devenv-image-hugo`) |
| `devenv-image-dotnet` | `dotnet/*` | `images/dotnet/` |
| `devenv-image-dotnet-claude` | `dotnet-claude/*` | `images/dotnet-claude/` (extends `devenv-image-dotnet`) |

Each image has its own tag namespace. Tagged builds require the matching tag to be on the current commit (`git describe --exact-match`). For day-to-day work, use the `-dev` variants, which skip the tag requirement and produce `<image>:dev`.

## Base images (no addon)

Each language has two targets:

```bash
# Production — requires <lang>/* tag on HEAD, builds <image>:<tag>
make build-golang
make build-python
make build-typescript
make build-hugo
make build-dotnet

# Local dev — builds <image>:dev
make build-golang-dev
make build-python-dev
make build-typescript-dev
make build-hugo-dev
make build-dotnet-dev
```

The image build passes your host `UID`/`GID` as build args so the container's `devuser` matches your host user. This avoids permission issues on bind-mounted files.

> **Hugo build context.** Unlike the other base-language images, `images/hugo/Dockerfile` installs Hugo via `installers/hugo/install.sh` (mirroring how the `*-claude` images install Claude Code), so `build-hugo`/`build-hugo-dev` build with the repo root as context (`-f images/hugo/Dockerfile .`) instead of `images/hugo/` — that's what makes `COPY installers/hugo/install.sh` resolve.

## Claude variants

The Claude variants are versioned independently from their base. `build-<lang>-claude` requires a `<lang>-claude/*` tag on HEAD and uses the nearest `<lang>/*` tag reachable from HEAD (`git describe --abbrev=0`) as its base — so bumping a Claude image does not require re-tagging or rebuilding the underlying language image.

Replace `<lang>` with `golang`, `python`, `typescript`, `hugo`, or `dotnet`:

```bash
# Production — requires <lang>-claude/* tag on HEAD;
# uses the most recent <lang>/* tag reachable from HEAD as base
make build-<lang>-claude

# Local dev — defaults to devenv-image-<lang>:dev as base;
# override with DEV_BASE=<tag> to pin a specific base version
make build-<lang>-claude-dev
make build-<lang>-claude-dev DEV_BASE=v1.0.0
```

The resolved base image (`devenv-image-<lang>:<tag>`) must already exist locally — build it from the relevant commit if not. The Makefile prints a clear error pointing you at the right `build-<lang>` or `build-<lang>-dev` target if the base is missing.

> **Known issue — Claude install script SHA verification.** The Claude variants verify the SHA digest of the upstream install script during the image build. When upstream rotates the script, the pinned digest goes stale and the build fails. For now the only workaround is to manually update the digest in `installers/claude/` (and the matching `images/<lang>-claude/Dockerfile` if it pins explicitly). A proper fix — auto-resolving the digest at build time or pinning to a versioned release artifact — is on the backlog.

## Listing available tags

```bash
make list-golang-tags
make list-golang-claude-tags
make list-python-tags
make list-python-claude-tags
make list-typescript-tags
make list-typescript-claude-tags
make list-hugo-tags
make list-hugo-claude-tags
make list-dotnet-tags
make list-dotnet-claude-tags
```

These shell out to `git tag --list "<namespace>/*"`.

## Related

- [commands.md](commands.md) — how `devenv` picks which image to run.
- [caches.md](caches.md) — host cache directories keyed by image version.
- [claude-code.md](claude-code.md) — extra runtime wiring used by the `*-claude` images.
