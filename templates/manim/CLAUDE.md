# Manim project

Math animations with Manim Community Edition (ManimCE), managed by uv.
The pinned manim version is in `pyproject.toml` — use APIs from that version.

## Project guidelines

Project-specific decisions live in `agent/guidelines.md`.

- If it exists, read it at the start of the session and follow it.
- If it doesn't exist, ask the user the questions below before writing any scene, then write the answers to `agent/guidelines.md`. If the format isn't 16:9, also write a `manim.cfg` with `pixel_width`, `pixel_height` and `frame_rate`.
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
9. Transitions between scenes — continuous (each starts on the previous last frame) or cuts?
10. Titles — one per scene? A title page or credits?
11. Text on screen — labels and explanations, or as little text as possible?

## Working with the user

- Keep messages short. Give the essentials; the user asks when they want more.
- Number everything you present so it can be referenced. Use a separate scheme for each kind of list so references never collide: `1, 2, 3` / `a, b, c` / `i, ii, iii` / `q1, q2, q3` and so on — e.g. decisions `q1–q3`, their options `a/b/c`, findings `1–3`.
- New scene or a change with design choices (what to show, how, layout, values): propose the plan and the open decisions, then stop and wait for answers. Mark a recommendation for each decision.
- Small, clearly specified fixes ("faster", "move the label", "drop the text"): just do them.
- When an answer leaves a real ambiguity (e.g. a value that changes what is counted), confirm it before building.
- Physical and technical content follows the user's description of the real system; don't invent it.

## Environment

- Headless container: no display. Never use `-p`/`--preview`; output goes to `media/`.
- Run manim only through the project env: `uv run manim ...` or the `tools/` scripts. Run `uv sync` first if `.venv/` is missing.
- Always run manim from the project root; running it from `scenes/` creates a stray `scenes/media/`.
- `.git` is read-only inside the container: don't stage or commit; tell the user which git command to run.
- The container has ~4 GB RAM; heavy renders (live-redrawn graphs at 1080p60) can come close to it.

## Structure

- Scenes live in `scenes/`. Files are `snake_case`, named after the topic or chapter.
- Scene classes are descriptive `PascalCase` and unique across the project.
- Shared helpers go in `scenes/common.py` (or further modules) — never scene classes there. Scenes import them with `from common import ...`.
- Movies are ordered scene lists in `[tool.movies.<name>]` of `pyproject.toml` (`"<file>:<SceneClass>"`, movie names `snake_case`). When adding, removing or reordering scenes, update the movie list. Resolve "not used by any movie" warnings.
- When scenes join without a cut, each scene starts on an exact rebuild of the previous scene's last frame. Build that end state with a shared function or class (in `common.py` if the scenes are in different files) and use it in both scenes, so they can't drift apart.

## Tools

- `tools/preview.sh <file> <Scene>` — render the last frame as a PNG and print its path.
- `tools/frames.sh <file> <Scene> <t1> [t2 ...]` — PNG stills at the given seconds; prints the video duration.
- `tools/render.sh <movie>` — render and join a movie into `media/final/<movie>.mp4`.
- `tools/render.sh <file> <Scene>` — render a single scene. `tools/render.sh` alone lists movies.

`QUALITY=l|m|h|p|k` overrides the quality. Iterate at low quality; render final quality only when the user asks.

- While iterating, render only the scene(s) you changed — not the whole movie — unless asked.
- Full-quality movie renders take minutes: run them in the background and report when done.

Prefer these tools over calling `uv run manim` directly. When a task repeats and no tool covers it, add a new script to `tools/` and list it here.

## Visual check

You can't watch video, but you can read PNGs. After every change, check the result yourself before reporting:

1. Run `tools/preview.sh` for the final state and `tools/frames.sh` at the moments that changed (transitions, mid-animation).
2. Read the PNGs and look for unintended overlaps, content cut off at the frame edge, text too small to read, misalignment, leftover objects, and wrong order of appearance.
3. Fix what you find, then report what you checked. Never hand over a render you haven't looked at.

## Layout

- Position objects relative to each other (`next_to`, `arrange`, `align_to`, `to_edge`) rather than with hard-coded coordinates.
- Keep content inside the frame with a margin; scale or split long text and formulas.
- Group objects that move together in a `VGroup`; remove objects that are no longer needed.

## LaTeX

TeX Live in this image is a curated set, not texlive-full.

- `Undefined control sequence` from a command whose package isn't loaded: add the package to a `TexTemplate` (once, in `common.py`) and continue.
- `File 'xyz.sty' not found`: the package isn't installed and can't be installed from inside the container. Stop and tell the user which `.sty` is missing and which Debian `texlive-*` package provides it. You may propose a workaround, but apply it only if the user agrees.

## Manim pitfalls

- `FadeIn`/`FadeOut` pause updaters on their mobject: an `always_redraw` part freezes, then jumps. Fade such objects through an opacity `ValueTracker` read inside the redraw.
- Every `self.play` starts with dt = 0, so dt-driven continuous motion stalls one frame per play. Drive it from `self.renderer.time`, or keep the motion inside a single play.
- `Succession` shows introducer mobjects (`Write`, `FadeIn`) at full strength before their turn — don't use it for staged reveals; use sequential plays.
- `Transform` between `Axes` keeps the old ranges, so `c2p` gives wrong positions afterwards. Use `ReplacementTransform` and draw on the new axes.
- `Axes.c2p` uses both axes: when grouping and moving a plot, keep the whole `Axes` in the group (hide an unwanted axis with opacity 0).
- `set_opacity` on open curves fills them; use `set_stroke(opacity=...)` for lines and plots.
- Text that changes words ("forward" → "backward") looks garbled with `Transform`; use `FadeTransform`.
- `axes.plot` samples coarsely by default; pass an explicit fine step for fast oscillations.

## Code

- Prefer explicit over implicit.
- Code explains itself through names. Comments only say why code looks the way it does, never what it does.
- Name a value only when it has meaning beyond where it's used — reused, or unclear from context. Inline values like `buff=0.3` or `run_time=2` are fine when the call makes their role obvious.
- Extract code to `common.py` once it's reused, not before.
- `from manim import *` is the accepted exception to explicit imports.
