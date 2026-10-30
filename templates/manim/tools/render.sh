#!/usr/bin/env bash
# Render a movie defined in [tool.movies] of pyproject.toml, or a single scene.
# Usage:
#   tools/render.sh                     list defined movies
#   tools/render.sh <movie>             render the movie's scenes in order, join into media/final/<movie>.mp4
#   tools/render.sh <file.py> <Scene>   render a single scene
# QUALITY=l|m|h|p|k picks the render quality (default: h).
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
source "$root/tools/_common.sh"
quality=${QUALITY:-h}
quality_dir "$quality" > /dev/null || exit 2

case $# in
    0)
        cd "$root"
        python3 -I tools/movie.py list
        ;;
    1)
        movie=$1
        cd "$root"
        plan=$(python3 -I tools/movie.py plan "$movie")
        mapfile -t entries <<< "$plan"

        list=$(mktemp)
        trap 'rm -f "$list"' EXIT
        declare -A rendered=()
        for entry in "${entries[@]}"; do
            file=${entry%%$'\t'*}
            scene=${entry#*$'\t'}
            video=$(video_path "$file" "$scene" "$quality")
            if [[ -z "${rendered[$file:$scene]:-}" ]]; then
                echo "==> $file:$scene"
                uv run manim -q"$quality" "$file" "$scene"
                [[ -f "$video" ]] || { echo "Expected video not found: $video" >&2; exit 1; }
                rendered[$file:$scene]=1
            fi
            # ffmpeg concat list: single-quote the path, escaping embedded quotes.
            printf "file '%s'\n" "$(realpath "$video" | sed "s/'/'\\\\''/g")" >> "$list"
        done

        # All scenes share one quality (same resolution/fps/codec), so streams are copied, not re-encoded.
        out=media/final/$movie.mp4
        mkdir -p media/final
        ffmpeg -v error -y -f concat -safe 0 -i "$list" -c copy "$out"
        echo
        echo "Movie: $(realpath "$out") (${#entries[@]} scenes)"
        ;;
    2)
        file=$(realpath "$1")
        scene=$2
        cd "$root"
        uv run manim -q"$quality" "$file" "$scene"
        video=$(video_path "$file" "$scene" "$quality")
        [[ -f "$video" ]] || { echo "Expected video not found: $video" >&2; exit 1; }
        echo
        echo "Video: $(realpath "$video")"
        ;;
    *)
        sed -n '2,7s/^# \{0,1\}//p' "$0" >&2
        exit 2
        ;;
esac
