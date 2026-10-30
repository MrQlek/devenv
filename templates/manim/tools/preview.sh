#!/usr/bin/env bash
# Render a scene's last frame as a PNG (no video) and print its path.
# Usage: tools/preview.sh <file.py> <Scene> [extra manim args...]
# QUALITY=l|m|h|p|k picks the render quality (default: l).
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <file.py> <Scene> [extra manim args...]" >&2
    exit 2
fi
root=$(cd "$(dirname "$0")/.." && pwd)
source "$root/tools/_common.sh"
file=$(realpath "$1")
scene=$2
shift 2
quality=${QUALITY:-l}
quality_dir "$quality" > /dev/null || exit 2

cd "$root"
uv run manim -q"$quality" -s "$file" "$scene" "$@"

# Last-frame images are named <Scene>_ManimCE_v<version>.png.
png=$(find "media/images/$(basename "$file" .py)" -regextype posix-extended -regex ".*/${scene}(_ManimCE_v[^/]*)?\.png" -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2-)
[[ -n "$png" ]] || { echo "No PNG found for $scene under media/images" >&2; exit 1; }
echo
echo "Last frame: $(realpath "$png")"
