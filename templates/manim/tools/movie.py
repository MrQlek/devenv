"""Read movie definitions from [tool.movies] in pyproject.toml. Used by tools/render.sh.

Usage:
  movie.py list           print defined movie names
  movie.py plan <movie>   validate <movie> and print its scenes in order as "<file>\t<Scene>"
"""

import ast
import re
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load_movies():
    with open(ROOT / "pyproject.toml", "rb") as f:
        return tomllib.load(f).get("tool", {}).get("movies", {})


def base_names(cls):
    for base in cls.bases:
        if isinstance(base, ast.Name):
            yield base.id
        elif isinstance(base, ast.Attribute):
            yield base.attr


def classes_in(path):
    """Return (all class names, leaf scene classes) defined at the top level of path.

    A scene class is one whose base name ends in "Scene" (Scene, ThreeDScene, ...) or is
    another scene class in the same file. Leaf scenes exclude classes used as a base by
    others, so shared base scenes aren't reported as unused.
    """
    tree = ast.parse(path.read_text(), filename=str(path))
    classes = [node for node in tree.body if isinstance(node, ast.ClassDef)]
    scenes = set()
    changed = True
    while changed:
        changed = False
        for cls in classes:
            if cls.name not in scenes and any(b.endswith("Scene") or b in scenes for b in base_names(cls)):
                scenes.add(cls.name)
                changed = True
    used_as_base = {b for cls in classes for b in base_names(cls)}
    return {cls.name for cls in classes}, scenes - used_as_base


def parse_entries(name, movie):
    scenes = movie.get("scenes") if isinstance(movie, dict) else None
    if not isinstance(scenes, list) or not scenes:
        return None, [f"movie '{name}': 'scenes' must be a non-empty list"]
    entries, errors = [], []
    for entry in scenes:
        if not isinstance(entry, str) or entry.count(":") != 1:
            errors.append(f"movie '{name}': entry {entry!r} must be '<file>:<SceneClass>'")
            continue
        file, scene = entry.split(":")
        entries.append((file, scene))
    return entries, errors


def plan(name):
    movies = load_movies()
    if name not in movies:
        defined = ", ".join(movies) or "none"
        sys.exit(f"No movie '{name}' in [tool.movies] of pyproject.toml (defined: {defined})")
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        sys.exit(f"Movie name '{name}' may only contain letters, digits, '_' and '-'")

    entries, errors = parse_entries(name, movies[name])
    if entries is None:
        sys.exit(errors[0])

    parsed = {}
    for file in dict.fromkeys(file for file, _ in entries):
        path = ROOT / file
        if not path.is_file():
            errors.append(f"movie '{name}': file not found: {file}")
            continue
        parsed[file] = classes_in(path)
    for file, scene in entries:
        if file in parsed and scene not in parsed[file][0]:
            errors.append(f"movie '{name}': no class {scene} in {file}")
    if errors:
        sys.exit("\n".join(errors))

    # Warn about scenes in this movie's files that no movie uses — likely forgotten.
    used = set()
    for other_name, other in movies.items():
        other_entries, _ = parse_entries(other_name, other)
        used.update(other_entries or [])
    for file, (_, leaf_scenes) in parsed.items():
        for scene in sorted(leaf_scenes):
            if (file, scene) not in used:
                print(f"warning: {file}:{scene} is not used by any movie", file=sys.stderr)

    for file, scene in entries:
        print(f"{file}\t{scene}")


def main():
    match sys.argv[1:]:
        case ["list"]:
            for name, movie in load_movies().items():
                entries, _ = parse_entries(name, movie)
                print(f"{name} ({len(entries or [])} scenes)")
        case ["plan", name]:
            plan(name)
        case _:
            sys.exit(__doc__)


if __name__ == "__main__":
    main()
