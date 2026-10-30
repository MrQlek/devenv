# Manim

Image: `devenv-image-manim` (or `devenv-image-manim-claude` with Claude Code CLI preinstalled). For creating math animations with [Manim Community Edition](https://www.manim.community/) (ManimCE).

## What's in the image

- Python 3.14 (same digest-pinned base as the `python` image)
- `uv` for project / dependency management
- Build dependencies for manim's native packages: `build-essential`, `pkg-config`, `libcairo2-dev`, `libpango1.0-dev` — pycairo and ManimPango publish no Linux wheels, so uv compiles them from source
- `ffmpeg` / `ffprobe`
- A curated TeX Live set for `Tex` / `MathTex`: `texlive-latex-base`, `-latex-recommended`, `-latex-extra`, `-fonts-recommended`, `-fonts-extra`, `-science`, `cm-super`, `dvisvgm` (not `texlive-full`, so exotic packages and CJK may be missing)
- The starter project template at `/opt/devenv/templates/manim/` and the `manim-init` command
- `fzf`, `ripgrep`, `fd` (aliased from `fdfind`), `jq`, `vim`, `git`, `make`

**manim itself is not installed in the image.** Each project pins its own version via `uv` (the starter template pins an exact version in `pyproject.toml`), so renders are reproducible per project and bumping manim doesn't require an image rebuild.

## Starter project

Inside the container, in an empty (or existing) project directory:

```bash
manim-init            # copy the template into the current directory; existing files are skipped
manim-init --force    # overwrite existing files with the template versions
uv sync               # first run compiles pycairo/ManimPango (~1 min), then cached
```

The template contains:

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Instructions for Claude Code: workflow, render-and-check loop, layout rules |
| `pyproject.toml` | uv project with `manim` pinned to an exact version, plus movie definitions under `[tool.movies]` |
| `manim.cfg` | manim config; disables the "newer version available" notice |
| `.gitignore` | Ignores `media/`, `.venv/`, `__pycache__/` |
| `scenes/common.py` | Shared helpers, imported by scenes with `from common import ...` |
| `scenes/intro.py`, `scenes/theorem.py` | Example movie split across two files; `Theorem` uses `MathTex`, so it doubles as a LaTeX smoke test |
| `tools/preview.sh` | Render only the last frame of a scene as a PNG and print its path |
| `tools/frames.sh` | Render a scene's video, then extract PNG stills at given timestamps (seconds) |
| `tools/render.sh` | Render a whole movie (joined into one mp4) or a single scene |
| `tools/movie.py`, `tools/_common.sh` | Internals used by the scripts above |

The scripts honour `QUALITY=l|m|h|p|k` (default `l` for preview/frames, `h` for render). They can be run from any directory; output lands in the project's `media/`.

```bash
tools/preview.sh scenes/theorem.py Theorem
tools/frames.sh  scenes/theorem.py Theorem 0.5 2 3.5
tools/render.sh  scenes/theorem.py Theorem   # single scene
tools/render.sh  example                      # whole movie → media/final/example.mp4
tools/render.sh                               # list defined movies
```

### Movies

A movie is an ordered list of scenes, defined in `pyproject.toml`. Scenes can come from any number of files, and the same scene can appear more than once:

```toml
[tool.movies.pythagoras]
scenes = [
    "scenes/intro.py:Intro",
    "scenes/proof.py:Setup",
    "scenes/proof.py:Proof",
    "scenes/outro.py:Outro",
]
```

`tools/render.sh pythagoras` validates the list before rendering (missing files or classes are errors; scene classes in the referenced files that no movie uses are reported as warnings), renders each distinct scene once, then joins them in order with ffmpeg into `media/final/pythagoras.mp4`. All scenes render at the same quality, so the join copies streams without re-encoding.

manim itself has no notion of movies or ordering — each `manim` call renders scenes from a single file, and output videos are named after the scene class (`media/videos/<file>/<quality>/<Scene>.mp4`).

The template is versioned with the image: `manim-init` always copies the template from the image tag you're running, so its pinned manim version matches that image's system libraries.

## Working with Claude Code

Claude can't watch a video, but it can read PNGs. `tools/preview.sh` and `tools/frames.sh` print absolute paths to stills so Claude can render, inspect the frames for overlaps / clipping / bad timing, and iterate. The template's `CLAUDE.md` describes this loop.

## Viewing renders

There is no display in the container. Rendered output lands in `./media/` inside the workspace, which is bind-mounted — open the videos from the host. Don't use manim's `-p` (preview) flag; there's no player to launch.

## Caches

Persisted on the host under `~/.devenv/`, keyed by image version. Full table in [../caches.md](../caches.md).

- `~/.devenv/manim-uv-cache/<version>/` → `~/.cache/uv` (download cache, including the locally built pycairo/ManimPango wheels)
- `~/.devenv/manim-uv-share/<version>/` → `~/.local/share/uv` (`uv tool install` environments)
- `~/.devenv/manim-uv-bin/<version>/` → `~/.uv-tools/bin` (uv tool shims, on `PATH`)

These are separate from the `python` image's `uv-*` caches so the two images never share tool environments built against a different interpreter. The cache directories are auto-created on first run by `shell/lib/manim.sh`.

The project's `.venv/` and `media/` live in the workspace and persist via the host bind mount.

## Ports

None — manim renders to files.

## Running

```bash
devenv manim dev
devenv manim-claude dev
```

For the Claude variant, see [../claude-code.md](../claude-code.md) for the first-run config scope prompt.

## Debugging

No remote debugger is wired up. Use `tools/preview.sh` / `tools/frames.sh` to inspect output, and manim's `-v DEBUG` for verbose logs.

## Related

- [../commands.md](../commands.md) — `devenv` invocation and arguments.
- [../building-images.md](../building-images.md) — building `devenv-image-manim` and `devenv-image-manim-claude`.
