_DEVENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_DEVENV_USER_HOME="$HOME"

if ! docker compose version &>/dev/null 2>&1; then
    echo "ERROR: 'docker compose' plugin not found. Install it: https://docs.docker.com/compose/install/"
fi

_devenv_resolve_claude_config() {
    local project=$1
    local language=$2
    local base_dir="${_DEVENV_USER_HOME}/.dockerdevenv/claude"
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

_devenv_check_docker() {
    if ! docker info &>/dev/null 2>&1; then
        echo "ERROR: Docker is not accessible without sudo. Set up rootless Docker instead: https://docs.docker.com/engine/security/rootless/"
        return 1
    fi
}

_devenv_validate_language() {
    local language=$1
    if ! [[ "$language" =~ ^[a-z][a-z0-9-]*$ ]]; then
        echo "ERROR: invalid language '$language' (must match ^[a-z][a-z0-9-]*\$)"
        return 1
    fi
}

_devenv_validate_ports() {
    local ports=$1
    if [ -n "$ports" ]; then
        IFS=',' read -ra port_list <<< "$ports"
        for port in "${port_list[@]}"; do
            if ! [[ "$port" =~ ^[0-9]+$ ]]; then
                echo "ERROR: invalid port '$port' (must be a number)"
                return 1
            fi
        done
    fi
}

_devenv_run_compose() {
    local user_home=$1
    local image_version=$2
    local compose_project=$3
    local compose_file=$4
    local claude_dir=$5
    local claude_file=$6
    shift 6

    _devenv_check_docker || return 1

    local env_prefix=""
    env_prefix="$env_prefix _DEVENV_USER_HOME=$user_home"
    env_prefix="$env_prefix IMAGE_VERSION=$image_version"
    env_prefix="$env_prefix COMPOSE_PROJECT_NAME=$compose_project"
    env_prefix="$env_prefix CLAUDE_CONFIG_DIR=$claude_dir"
    env_prefix="$env_prefix CLAUDE_CONFIG_FILE=$claude_file"

    env $env_prefix docker compose -f "$compose_file" "$@"
}

devenv() {
    local language=${1:-golang}
    local version=${2:-dev}
    local ports=${3:-}
    local public_ports=${4:-}

    _devenv_validate_language "$language" || return 1

    local project=$(pwd | sed 's/\//-/g' | sed 's/^-//')
    local container_name="devenv-${project}-${language}"
    local compose_file="$_DEVENV_DIR/compose/docker-compose.${language}.yml"

    if [ ! -f "$compose_file" ]; then
        echo "ERROR: no compose file found for language '$language' (looked for $compose_file)"
        return 1
    fi

    local claude_dir=""
    local claude_file=""
    if [[ "$language" == *"claude"* ]]; then
        claude_dir=$(_devenv_resolve_claude_config "$project" "$language")
        claude_file="${claude_dir}.json"
    fi

    _devenv_validate_ports "$ports" || return 1
    _devenv_validate_ports "$public_ports" || return 1

    local port_args=""
    if [ -n "$ports" ]; then
        IFS=',' read -ra port_list <<< "$ports"
        for port in "${port_list[@]}"; do
            port_args="$port_args -p 127.0.0.1:$port:$port"
        done
    fi
    if [ -n "$public_ports" ]; then
        IFS=',' read -ra port_list <<< "$public_ports"
        for port in "${port_list[@]}"; do
            port_args="$port_args -p 0.0.0.0:$port:$port"
        done
    fi

    local git_mount=""
    if [ -e "$(pwd)/.git" ]; then
        git_mount="-v $(pwd)/.git:/workspace/.git:ro"
    fi

    _devenv_run_compose \
        "$_DEVENV_USER_HOME" \
        "$version" \
        "$project" \
        "$compose_file" \
        "$claude_dir" \
        "$claude_file" \
        run \
        --name "$container_name" \
        --rm \
        $port_args \
        -v $(pwd):/workspace \
        $git_mount \
        $language \
        bash
}

devenv-connect() {
    local language=${1:-golang}

    _devenv_validate_language "$language" || return 1

    local project=$(pwd | sed 's/\//-/g' | sed 's/^-//')
    local container_name="devenv-${project}-${language}"

    _devenv_check_docker || return 1
    docker exec -it $container_name bash
}

devenv-exec() {
    local language=${1:-golang}

    _devenv_validate_language "$language" || return 1

    local project=$(pwd | sed 's/\//-/g' | sed 's/^-//')
    local container_name="devenv-${project}-${language}"
    shift 1

    if [ $# -eq 0 ]; then
        echo "Usage: devenv-exec [language] <command> [args...]"
        return 1
    fi

    _devenv_check_docker || return 1
    docker exec $container_name "$@"
}