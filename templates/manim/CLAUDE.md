# Manim project

Math animations with Manim Community Edition (ManimCE), managed by uv.
The pinned manim version is in `pyproject.toml` — use APIs from that version.

## Project guidelines

Project-specific decisions live in `agent/guidelines.md`.

- If it exists, read it at the start of the session and follow it.
- If it doesn't exist, ask the user the questions below before writing any scene, then write the answers to `agent/guidelines.md`. If the format isn't 16:9, also set `pixel_width`, `pixel_height` and `frame_rate` in `manim.cfg`.
- When the user changes a preference, update the file.

Questions:

1. Purpose and audience — what kind of animations, who watches them, at what level?
2. Output format — aspect ratio, resolution, fps?
3. Visual style — background, color palette, fonts?
4. Math — any notation conventions?
5. Pacing — target length per movie, animation speed, pauses?
6. Audio — voiceover, music, silent? Subtitles?
7. Language of on-screen text?
8. Anything to avoid?

## Environment

- Headless container: no display. Never use `-p`/`--preview`; output goes to `media/`.
- Run manim only through the project env: `uv run manim ...` or the `tools/` scripts. Run `uv sync` first if `.venv/` is missing.

## Structure

- Scenes live in `scenes/`. Files are `snake_case`, named after the topic or chapter.
- Scene classes are descriptive `PascalCase` and unique across the project.
- Shared helpers go in `scenes/common.py` (or further modules) — never scene classes there. Scenes import them with `from common import ...`.
- Movies are ordered scene lists in `[tool.movies.<name>]` of `pyproject.toml` (`"<file>:<SceneClass>"`, movie names `snake_case`). When adding, removing or reordering scenes, update the movie list. Resolve "not used by any movie" warnings.

## Tools

- `tools/preview.sh <file> <Scene>` — render the last frame as a PNG and print its path.
- `tools/frames.sh <file> <Scene> <t1> [t2 ...]` — PNG stills at the given seconds; prints the video duration.
- `tools/render.sh <movie>` — render and join a movie into `media/final/<movie>.mp4`.
- `tools/render.sh <file> <Scene>` — render a single scene. `tools/render.sh` alone lists movies.

`QUALITY=l|m|h|p|k` overrides the quality. Iterate at low quality; render final quality only when the user asks.

Prefer these tools over calling `uv run manim` directly. When a task repeats and no tool covers it, add a new script to `tools/` and list it here.

## Visual check

You can't watch video, but you can read PNGs. After creating a new scene or significantly changing one, propose a visual check — don't run it unprompted. If the user agrees:

1. Run `tools/preview.sh` for the final state and `tools/frames.sh` with timestamps covering the key animations.
2. Read the PNGs and look for unintended overlaps, content cut off at the frame edge, text too small to read, misalignment, and leftover objects that should be gone.
3. Report what you found and fix it.

## Layout

- Position objects relative to each other (`next_to`, `arrange`, `align_to`, `to_edge`) rather than with hard-coded coordinates.
- Keep content inside the frame with a margin; scale or split long text and formulas.
- Group objects that move together in a `VGroup`; remove objects that are no longer needed.

## LaTeX

TeX Live in this image is a curated set, not texlive-full.

- `Undefined control sequence` from a command whose package isn't loaded: add the package to a `TexTemplate` (once, in `common.py`) and continue.
- `File 'xyz.sty' not found`: the package isn't installed and can't be installed from inside the container. Stop and tell the user which `.sty` is missing and which Debian `texlive-*` package provides it. You may propose a workaround, but apply it only if the user agrees.

## Code

- Prefer explicit over implicit.
- Code explains itself through names. Comments only say why code looks the way it does, never what it does.
- Name a value only when it has meaning beyond where it's used — reused, or unclear from context. Inline values like `buff=0.3` or `run_time=2` are fine when the call makes their role obvious.
- Extract code to `common.py` once it's reused, not before.
- `from manim import *` is the accepted exception to explicit imports.
