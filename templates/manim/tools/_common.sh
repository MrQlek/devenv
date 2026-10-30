# Shared helpers for the render scripts. Sourced, not executed.

# Quality flag -> manim's output subdirectory (<height>p<fps>).
quality_dir() {
    case "$1" in
        l) echo 480p15 ;;
        m) echo 720p30 ;;
        h) echo 1080p60 ;;
        p) echo 1440p60 ;;
        k) echo 2160p60 ;;
        *) echo "QUALITY must be one of l m h p k, got: $1" >&2; return 2 ;;
    esac
}

# Video manim writes for <file.py> <Scene> at quality <q>, relative to the project root.
video_path() {
    local file=$1 scene=$2 quality=$3
    echo "media/videos/$(basename "$file" .py)/$(quality_dir "$quality")/$scene.mp4"
}
