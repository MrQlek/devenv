_DEVENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_DEVENV_USER_HOME="$HOME"

if docker compose version &>/dev/null 2>&1; then
    _DEVENV_COMPOSE="docker compose"
elif docker-compose version &>/dev/null 2>&1; then
    _DEVENV_COMPOSE="docker-compose"
else
    echo "ERROR: neither 'docker compose' nor 'docker-compose' found"
fi

_devenv_run_compose() {
    local user_home=$1
    local go_release=$2
    local image_version=$3
    local compose_project=$4
    shift 4

    local env_prefix=""
    env_prefix="$env_prefix _DEVENV_USER_HOME=$user_home"
    env_prefix="$env_prefix GO_RELEASE=$go_release"
    env_prefix="$env_prefix IMAGE_VERSION=$image_version"
    env_prefix="$env_prefix COMPOSE_PROJECT_NAME=$compose_project"

    if docker info &>/dev/null 2>&1; then
        env $env_prefix $_DEVENV_COMPOSE "$@"
    else
        echo "Docker requires sudo to run. Do you want to escalate to root? [y/N]"
        read -r answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            sudo env $env_prefix $_DEVENV_COMPOSE "$@"
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
        -f "$_DEVENV_DIR/compose/docker-compose.yml" \
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
