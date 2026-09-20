# .NET

Image: `devenv-image-dotnet` (or `devenv-image-dotnet-claude` with Claude Code CLI preinstalled). Targets .NET 10.0 desktop GUI development with **Avalonia** and **Photino**.

## What's in the image

- .NET SDK 10.0.400 / runtime 10.0.11, pinned by digest in `images/dotnet/Dockerfile`
- Base is Ubuntu **noble** (24.04), not Debian bookworm — Microsoft ships no bookworm variant for the 10.0 SDK. Noble ships a uid-1000 `ubuntu` user, which the Dockerfile deletes so `devuser` can claim uid 1000 (same pattern as the TypeScript image and its `node` user).
- `libfontconfig1` + `fonts-dejavu-core` — see [Why those two packages](#why-those-two-packages)
- `fzf`, `ripgrep`, `fd` (aliased from `fdfind`), `jq`, `vim`, `git`, `make`

**Avalonia and Photino are deliberately not in the image.** They are ordinary NuGet packages, restored per project by `dotnet restore` into the NuGet cache below. Baking them in would pin a version for every project on the machine; leaving them out means each project picks its own.

Both work with the SDK as shipped — no extra build configuration, no extra system packages:

| Package | Latest | Usable from a `net10.0` project? |
|---|---|---|
| `Avalonia` | 12.1.1 | yes |
| `Avalonia.Templates` | 12.1.1 | n/a (templates) |
| `Photino.NET` | 4.0.16 | yes |
| `Photino.Blazor` | 4.0.13 | yes |

These packages ship `net8.0`/`netstandard2.0` assemblies rather than a dedicated `net10.0` target; a `net10.0` project consumes them normally, so no version pinning or `TargetFramework` juggling is required.

### Why those two packages

Avalonia renders through SkiaSharp, whose native `libSkiaSharp` links against system fontconfig. Without `libfontconfig1` (and at least one font family), Avalonia headless UI tests fail at startup with `Unable to load shared library 'libSkiaSharp'`. Those two packages are ~2 MB and are the only GUI-adjacent things installed. Everything else Avalonia and Photino need ships inside their NuGet packages.

## Headless: what runs here and what doesn't

This image has **no display server** — no X11 socket from the host, no Xvfb, no VNC. That is a deliberate choice.

| Task | In the container |
|---|---|
| `dotnet build` / `dotnet publish`, both frameworks | ✅ |
| `dotnet format`, analyzers, NuGet work | ✅ |
| `dotnet test` over your own code (view models, services, IPC handlers) | ✅ |
| `dotnet test` driving Avalonia UI via `Avalonia.Headless` | ✅ |
| `dotnet test` constructing a `PhotinoWindow` | ❌ see below |
| `dotnet run` on an Avalonia or Photino app | ❌ no display |

Run the app itself on the host. The workspace is bind-mounted, so the same tree builds in both places.

### Nothing GUI-related is needed to build

Both frameworks build with the SDK alone. Their native components (`libPhotino.Native.so`, SkiaSharp's `libSkiaSharp.so`) ship inside the NuGet packages and are merely copied to the output directory — the compiler never loads them. A build failure here is a real build failure, not a missing system library.

### The two frameworks differ at test time

**Avalonia has a headless backend.** `Avalonia.Headless` (with `Avalonia.Headless.XUnit` or `Avalonia.Headless.NUnit`) runs a real Avalonia application lifecycle with no display, so `dotnet test` genuinely exercises your views here. Skia-backed frame capture (`UseHeadlessDrawing = false`) is what needs the fontconfig packages above.

**Photino has no headless equivalent.** Its whole job is hosting the operating system's native webview — GTK3 + WebKitGTK on Linux — so there is no headless backend to substitute. Constructing a `PhotinoWindow` makes the runtime load `libPhotino.Native.so`, which fails with `Unable to load shared library` because WebKitGTK is not installed, and would then need a display even if it were. This is not fixable by adding packages to a headless image.

So structure Photino work with the window as a thin shell: keep logic in classes a test can construct directly, and test the window itself on the host. Note that no headless *browser* (Chromium, Playwright) is involved in any of this — that only enters if you separately test a Photino app's web content as an ordinary web page.

## Caches

Persisted on the host under `~/.devenv/`, keyed by image version. Full table in [../caches.md](../caches.md).

- `~/.devenv/nuget/<version>/` → `~/.nuget/packages` (NuGet global packages folder, `NUGET_PACKAGES`)
- `~/.devenv/dotnet-tools/<version>/` → `~/.dotnet/tools` (`dotnet tool install -g` shims, on `PATH`)
- `~/.devenv/dotnet-templates/<version>/` → `~/.templateengine` (`dotnet new install` templates)

The cache directories are auto-created on first run by `shell/lib/dotnet.sh`.

The template cache is what makes the workflow below stick: `dotnet new install Avalonia.Templates` survives container restarts, so you install it once per image version rather than every session.

### Project `bin/` and `obj/`

Build output lives inside the workspace and persists via the host bind mount, not under `~/.devenv/`. Note that `obj/` records absolute paths — a tree built in the container has `/workspace/...` baked into its intermediate files, so run `dotnet clean` (or delete `bin/`+`obj/`) when switching between building in the container and on the host.

## Ports

- `8080` → ASP.NET Core default (bound to `127.0.0.1`)

Declared in `compose/dotnet.yml`. The SDK image sets `ASPNETCORE_HTTP_PORTS=8080`, so this is useful when your solution has a web or API project alongside the GUI app. Desktop GUI apps do not serve over HTTP, and Photino.Blazor serves its Blazor content to the embedded webview over a custom scheme rather than a TCP port — this port does nothing for them.

## Running

```bash
devenv dotnet dev
devenv dotnet-claude dev
```

For the Claude variant, see [../claude-code.md](../claude-code.md) for the first-run config scope prompt.

## Typical workflow

### Avalonia

```bash
dotnet new install Avalonia.Templates    # once per image version — persists via the template cache
dotnet new avalonia.app -o MyApp
cd MyApp
dotnet build
dotnet test                              # if you add an Avalonia.Headless test project
```

Then run `dotnet run` on the host to see the window.

### Photino

```bash
dotnet new console -o MyApp
cd MyApp
dotnet add package Photino.NET           # or Photino.Blazor for a Blazor UI
dotnet build
```

Again, run it on the host — Photino needs WebKitGTK and a display.

### Target framework

This is a .NET **10.0** SDK. It *builds* projects targeting `net8.0`, `net9.0` or `net10.0` — the older reference assemblies are restored from NuGet like any other package.

It only carries the **10.0 runtime**, though, so anything that has to *execute* the built assemblies in the container needs a `net10.0` target. In practice that means `dotnet test`: a test project left on `net8.0` builds fine and then fails at run with `You must install .NET to run this application`. Retarget the test project (and anything it references):

```xml
<TargetFramework>net10.0</TargetFramework>
```

Since Avalonia and Photino are consumed fine from `net10.0` (see the table above), this is a one-line edit per project.

## Debugging

There is no remote debugger wired into this image — see [../debugger-setup.md#net-dotnet-dotnet-claude](../debugger-setup.md#net-dotnet-dotnet-claude) for why, and for the `pipeTransport` approach if you need to attach.

## Related

- [../commands.md](../commands.md) — `devenv` invocation and arguments.
- [../building-images.md](../building-images.md) — building `devenv-image-dotnet` and `devenv-image-dotnet-claude`.
