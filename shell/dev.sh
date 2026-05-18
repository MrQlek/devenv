_DEVENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_DEVENV_USER_HOME="$HOME"

if docker compose version &>/dev/null 2>&1; then
    _DEVENV_COMPOSE="docker compose"
elif docker-compose version &>/dev/null 2>&1; then
    _DEVENV_COMPOSE="docker-compose"
else
    echo "ERROR: neither 'docker compose' nor 'docker-compose' found"
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

    case "$choice" in
        2)
            mkdir -p "$lang_dir"
            touch "${lang_dir}.json"
            ln -s "$lang_dir" "$project_dir"
            ln -sf "${lang_dir}.json" "${project_dir}.json"
            ;;
        3)
            mkdir -p "$shared_dir"
            touch "${shared_dir}.json"
            ln -s "$shared_dir" "$project_dir"
            ln -sf "${shared_dir}.json" "${project_dir}.json"
            ;;
        *)
            mkdir -p "$project_dir"
            touch "${project_dir}.json"
            ;;
    esac

    echo "$project_dir"
}

_devenv_run_compose() {
    local user_home=$1
    local go_release=$2
    local image_version=$3
    local compose_project=$4
    local compose_file=$5
    local claude_dir=$6
    local claude_file=$7
    shift 7

    local env_prefix=""
    env_prefix="$env_prefix _DEVENV_USER_HOME=$user_home"
    env_prefix="$env_prefix GO_RELEASE=$go_release"
    env_prefix="$env_prefix IMAGE_VERSION=$image_version"
    env_prefix="$env_prefix COMPOSE_PROJECT_NAME=$compose_project"
    env_prefix="$env_prefix CLAUDE_CONFIG_DIR=$claude_dir"
    env_prefix="$env_prefix CLAUDE_CONFIG_FILE=$claude_file"

    if docker info &>/dev/null 2>&1; then
        env $env_prefix $_DEVENV_COMPOSE -f "$compose_file" "$@"
    else
        echo "Docker requires sudo to run. Do you want to escalate to root? [y/N]"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            sudo env $env_prefix $_DEVENV_COMPOSE -f "$compose_file" "$@"
        else
            echo "Aborted."
            return 1
        fi
    fi
}

devenv() {
    local language=${1:-golang}
    local release=${2:-1.26}
    local version=${3:-dev}
    local ports=${4:-}
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

    local port_args=""
    if [ -n "$ports" ]; then
        IFS=',' read -ra port_list <<< "$ports"
        for port in "${port_list[@]}"; do
            port_args="$port_args -p $port:$port"
        done
    fi

    _devenv_run_compose \
        "$_DEVENV_USER_HOME" \
        "$release" \
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
        $language \
        bash
}

devenv-connect() {
    local language=${1:-golang}
    local project=$(pwd | sed 's/\//-/g' | sed 's/^-//')
    local container_name="devenv-${project}-${language}"

    if docker info &>/dev/null 2>&1; then
        docker exec -it $container_name bash
    else
        echo "Docker requires sudo to run. Do you want to escalate to root? [y/N]"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            sudo docker exec -it $container_name bash
        else
            echo "Aborted."
            return 1
        fi
    fi
}

devenv-exec() {
    local language=${1:-golang}
    local project=$(pwd | sed 's/\//-/g' | sed 's/^-//')
    local container_name="devenv-${project}-${language}"
    shift 1

    if [ $# -eq 0 ]; then
        echo "Usage: devenv-exec [language] <command> [args...]"
        return 1
    fi

    if docker info &>/dev/null 2>&1; then
        docker exec $container_name "$@"
    else
        echo "Docker requires sudo to run. Do you want to escalate to root? [y/N]"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            sudo docker exec $container_name "$@"
        else
            echo "Aborted."
            return 1
        fi
    fi
}