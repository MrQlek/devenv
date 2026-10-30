#!/usr/bin/env bash
# Render a scene to video, then extract PNG stills at the given timestamps (seconds).
# Usage: tools/frames.sh <file.py> <Scene> <t1> [t2 ...]
# QUALITY=l|m|h|p|k picks the render quality (default: l).
set -euo pipefail

if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <file.py> <Scene> <t1> [t2 ...]" >&2
    exit 2
fi
root=$(cd "$(dirname "$0")/.." && pwd)
source "$root/tools/_common.sh"
file=$(realpath "$1")
scene=$2
shift 2
for t in "$@"; do
    [[ "$t" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "Timestamp must be seconds, got: $t" >&2; exit 2; }
done
quality=${QUALITY:-l}
quality_dir "$quality" > /dev/null || exit 2

cd "$root"
uv run manim -q"$quality" "$file" "$scene"

video=$(video_path "$file" "$scene" "$quality")
[[ -f "$video" ]] || { echo "Expected video not found: $video" >&2; exit 1; }
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video")

out=media/frames/$scene
mkdir -p "$out"
echo
echo "Video: $(realpath "$video") (duration ${duration}s)"
for t in "$@"; do
    png=$out/${scene}_t${t}.png
    ffmpeg -v error -y -ss "$t" -i "$video" -frames:v 1 "$png"
    if [[ -s "$png" ]]; then
        echo "Frame at ${t}s: $(realpath "$png")"
    else
        echo "Frame at ${t}s: none (past end of video?)" >&2
        rm -f "$png"
    fi
done
