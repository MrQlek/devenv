_DEVENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
_DEVENV_USER_HOME="$HOME"

if ! docker compose version &>/dev/null 2>&1; then
    echo "ERROR: 'docker compose' plugin not found. Install it: https://docs.docker.com/compose/install/"
fi

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

# Sources shell/lib/*.sh fresh on every invocation.
# Aborts if any function matching the hook pattern already exists — refuses to
# overwrite something we didn't define this call.
_devenv_load_libs() {
    [ -d "$_DEVENV_DIR/shell/lib" ] || return 0

    local pre_existing
    pre_existing=$(compgen -A function 2>/dev/null | grep -E '^_devenv_lib_[a-z0-9_]+_hook$' || true)
    if [ -n "$pre_existing" ]; then
        echo "ERROR: dev.sh: pre-existing functions match the hook pattern '_devenv_lib_*_hook':" >&2
        echo "$pre_existing" | sed 's/^/  - /' >&2
        echo "Refusing to source shell/lib/ to avoid running unintended code." >&2
        echo "Unset them ('unset -f <name>') and retry." >&2
        return 1
    fi

    local lib
    for lib in "$_DEVENV_DIR/shell/lib"/*.sh; do
        [ -f "$lib" ] && source "$lib"
    done
}

_devenv_unload_libs() {
    local fn
    for fn in $(compgen -A function 2>/dev/null | grep -E '^_devenv_lib_[a-z0-9_]+_hook$' || true); do
        unset -f "$fn"
    done
}

_devenv_resolve_compose_files() {
    local language=$1
    local -n _out_files=$2
    local -n _out_image=$3
    local base_dir="$_DEVENV_DIR/compose"

    _out_files=("$base_dir/base.yml")

    local base_lang="$language"
    local with_claude=0
    if [[ "$language" == *-claude ]]; then
        base_lang="${language%-claude}"
        with_claude=1
    fi

    local lang_file="$base_dir/${base_lang}.yml"
    if [ ! -f "$lang_file" ]; then
        echo "ERROR: no compose file found for language '$base_lang' (looked for $lang_file)"
        return 1
    fi
    _out_files+=("$lang_file")

    if [ "$with_claude" -eq 1 ]; then
        _out_files+=("$base_dir/claude.yml")
        local combo_file="$base_dir/${language}.yml"
        [ -f "$combo_file" ] && _out_files+=("$combo_file")
        _out_image="devenv-image-${base_lang}-claude"
    else
        _out_image="devenv-image-${base_lang}"
    fi
}

_devenv_run_compose() {
    local user_home=$1
    local image_version=$2
    local compose_project=$3
    local devenv_image=$4
    local devenv_lang=$5
    local claude_dir=$6
    local claude_file=$7
    shift 7

    local -a compose_files=()
    while [ $# -gt 0 ] && [ "$1" != "--" ]; do
        compose_files+=("$1")
        shift
    done
    if [ $# -eq 0 ]; then
        echo "ERROR: _devenv_run_compose: missing '--' separator between compose files and docker compose args"
        return 1
    fi
    shift  # consume "--"

    _devenv_check_docker || return 1

    local -a file_args=()
    for f in "${compose_files[@]}"; do
        file_args+=(-f "$f")
    done

    env \
        _DEVENV_USER_HOME="$user_home" \
        IMAGE_VERSION="$image_version" \
        COMPOSE_PROJECT_NAME="$compose_project" \
        DEVENV_IMAGE="$devenv_image" \
        DEVENV_LANG="$devenv_lang" \
        CLAUDE_CONFIG_DIR="$claude_dir" \
        CLAUDE_CONFIG_FILE="$claude_file" \
        docker compose "${file_args[@]}" "$@"
}

# Outputs via _DEVENV_PREP_* globals — too many return values for namerefs.
# Callers must read the globals immediately after invocation.
_devenv_prepare() {
    local language=$1
    local ports=$2
    local public_ports=$3

    _devenv_validate_language "$language" || return 1
    _devenv_validate_ports "$ports" || return 1
    _devenv_validate_ports "$public_ports" || return 1
    _devenv_load_libs || return 1

    _DEVENV_PREP_PROJECT=$(pwd | sed 's/\//-/g' | sed 's/^-//')
    _DEVENV_PREP_CONTAINER_NAME="devenv-${_DEVENV_PREP_PROJECT}-${language}"

    _DEVENV_PREP_COMPOSE_FILES=()
    _DEVENV_PREP_IMAGE=""
    _devenv_resolve_compose_files "$language" _DEVENV_PREP_COMPOSE_FILES _DEVENV_PREP_IMAGE || return 1

    _DEVENV_PREP_CLAUDE_DIR=""
    _DEVENV_PREP_CLAUDE_FILE=""

    local hook
    for hook in $(compgen -A function 2>/dev/null | grep -E '^_devenv_lib_[a-z0-9_]+_hook$' || true); do
        "$hook" "$language" "$_DEVENV_PREP_PROJECT" || return 1
    done

    _DEVENV_PREP_PORT_ARGS=""
    if [ -n "$ports" ]; then
        IFS=',' read -ra port_list <<< "$ports"
        for port in "${port_list[@]}"; do
            _DEVENV_PREP_PORT_ARGS="$_DEVENV_PREP_PORT_ARGS -p 127.0.0.1:$port:$port"
        done
    fi
    if [ -n "$public_ports" ]; then
        IFS=',' read -ra port_list <<< "$public_ports"
        for port in "${port_list[@]}"; do
            _DEVENV_PREP_PORT_ARGS="$_DEVENV_PREP_PORT_ARGS -p 0.0.0.0:$port:$port"
        done
    fi

    _DEVENV_PREP_GIT_MOUNT=""
    if [ -e "$(pwd)/.git" ]; then
        _DEVENV_PREP_GIT_MOUNT="-v $(pwd)/.git:/workspace/.git:ro"
    fi

    _devenv_unload_libs
}

devenv() {
    local language=${1:-golang}
    local version=${2:-dev}
    local ports=${3:-}
    local public_ports=${4:-}

    _devenv_prepare "$language" "$ports" "$public_ports" || return 1

    _devenv_run_compose \
        "$_DEVENV_USER_HOME" \
        "$version" \
        "$_DEVENV_PREP_PROJECT" \
        "$_DEVENV_PREP_IMAGE" \
        "$language" \
        "$_DEVENV_PREP_CLAUDE_DIR" \
        "$_DEVENV_PREP_CLAUDE_FILE" \
        "${_DEVENV_PREP_COMPOSE_FILES[@]}" \
        -- \
        run \
        --name "$_DEVENV_PREP_CONTAINER_NAME" \
        --rm \
        $_DEVENV_PREP_PORT_ARGS \
        -v $(pwd):/workspace \
        $_DEVENV_PREP_GIT_MOUNT \
        devenv \
        bash
}

devenv-inspect() {
    local raw=0
    local -a positional=()
    local a
    for a in "$@"; do
        if [ "$a" = "--raw" ]; then
            raw=1
        else
            positional+=("$a")
        fi
    done
    set -- "${positional[@]}"

    local language=${1:-golang}
    local version=${2:-dev}
    local ports=${3:-}
    local public_ports=${4:-}

    _devenv_prepare "$language" "$ports" "$public_ports" || return 1

    local -a config_args=(config)
    [ "$raw" -eq 1 ] && config_args+=(--no-interpolate)

    echo "# === Merged compose config ==="
    _devenv_run_compose \
        "$_DEVENV_USER_HOME" \
        "$version" \
        "$_DEVENV_PREP_PROJECT" \
        "$_DEVENV_PREP_IMAGE" \
        "$language" \
        "$_DEVENV_PREP_CLAUDE_DIR" \
        "$_DEVENV_PREP_CLAUDE_FILE" \
        "${_DEVENV_PREP_COMPOSE_FILES[@]}" \
        -- \
        "${config_args[@]}"

    echo
    echo "# === Runtime additions (passed to 'docker compose run') ==="
    echo "container name: $_DEVENV_PREP_CONTAINER_NAME"
    echo "service:        devenv"
    echo "command:        bash"
    echo "extra ports:    ${_DEVENV_PREP_PORT_ARGS:- (none)}"
    echo "workspace:      -v $(pwd):/workspace"
    [ -n "$_DEVENV_PREP_GIT_MOUNT" ] && echo "git mount:      $_DEVENV_PREP_GIT_MOUNT"
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