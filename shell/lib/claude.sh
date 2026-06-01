_devenv_resolve_claude_config() {
    local project=$1
    local language=$2
    local base_dir="${_DEVENV_USER_HOME}/.devenv/claude"
    local project_dir="${base_dir}/projects/${project}"
    local lang_dir="${base_dir}/languages/${language}"
    local shared_dir="${base_dir}/shared"

    if [ -e "$project_dir" ]; then
        echo "$project_dir"
        return
    fi

    echo "No Claude config found for project: $project" >&2
    echo "  1) Project-specific config" >&2
    echo "  2) Shared per-language ($language)" >&2
    echo "  3) Shared globally" >&2
    printf "Choose [1/2/3]: " >&2
    read -r choice

    mkdir -p "${base_dir}/projects"
    chmod 700 "$base_dir" "${base_dir}/projects"

    case "$choice" in
        2)
            echo "WARNING: Any setting, MCP server, or hook written by Claude this session will persist into all other projects using the per-language ($language) scope." >&2
            mkdir -p "$lang_dir"
            chmod 700 "${base_dir}/languages" "$lang_dir"
            touch "${lang_dir}.json"
            chmod 600 "${lang_dir}.json"
            ln -s "$lang_dir" "$project_dir"
            ln -sf "${lang_dir}.json" "${project_dir}.json"
            ;;
        3)
            echo "WARNING: Any setting, MCP server, or hook written by Claude this session will persist into all other projects using the global shared scope." >&2
            mkdir -p "$shared_dir"
            chmod 700 "$shared_dir"
            touch "${shared_dir}.json"
            chmod 600 "${shared_dir}.json"
            ln -s "$shared_dir" "$project_dir"
            ln -sf "${shared_dir}.json" "${project_dir}.json"
            ;;
        *)
            mkdir -p "$project_dir"
            chmod 700 "$project_dir"
            touch "${project_dir}.json"
            chmod 600 "${project_dir}.json"
            ;;
    esac

    echo "$project_dir"
}

# Lib hook contract: discovered and called by _devenv_prepare for every loaded lib.
# Each hook self-gates on the language string and may write to any _DEVENV_PREP_* global.
_devenv_lib_claude_hook() {
    local language=$1
    local project=$2
    [[ "$language" == *-claude ]] || return 0
    _DEVENV_PREP_CLAUDE_DIR=$(_devenv_resolve_claude_config "$project" "$language")
    _DEVENV_PREP_CLAUDE_FILE="${_DEVENV_PREP_CLAUDE_DIR}.json"
}
