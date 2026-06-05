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

_devenv_project_slug() {
    pwd | sed 's|/|-|g; s/^-//'
}

_devenv_container_name() {
    local language=$1
    printf 'devenv-%s-%s\n' "$(_devenv_project_slug)" "$language"
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

# Parses "<lang>" or "<lang>-<addon>" into separate vars via namerefs.
_devenv_split_language() {
    local input=$1
    local -n _out_lang=$2
    local -n _out_addon=$3
    if [[ "$input" == *-* ]]; then
        _out_lang="${input%-*}"
        _out_addon="${input##*-}"
    else
        _out_lang="$input"
        _out_addon=""
    fi
}

_devenv_resolve_compose_files() {
    local language=$1
    local -n _out_files=$2
    local -n _out_image=$3
    local base_dir="$_DEVENV_DIR/compose"

    local base_lang addon
    _devenv_split_language "$language" base_lang addon

    local lang_file="$base_dir/${base_lang}.yml"
    if [ ! -f "$lang_file" ]; then
        echo "ERROR: no compose file for language '$base_lang' (looked for $lang_file)"
        return 1
    fi
    _out_files=("$base_dir/base.yml" "$lang_file")
    _out_image="devenv-image-${base_lang}"

    if [ -n "$addon" ]; then
        local addon_file="$base_dir/${addon}.yml"
        if [ ! -f "$addon_file" ]; then
            echo "ERROR: no compose file for addon '$addon' (looked for $addon_file)"
            return 1
        fi
        _out_files+=("$addon_file")
        local combo_file="$base_dir/${base_lang}-${addon}.yml"
        [ -f "$combo_file" ] && _out_files+=("$combo_file")
        _out_image="devenv-image-${base_lang}-${addon}"
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
    local version=$2
    local ports=$3
    local public_ports=$4

    _devenv_validate_language "$language" || return 1
    _devenv_validate_ports "$ports" || return 1
    _devenv_validate_ports "$public_ports" || return 1
    _devenv_load_libs || return 1

    _DEVENV_PREP_PROJECT=$(_devenv_project_slug)
    _DEVENV_PREP_CONTAINER_NAME=$(_devenv_container_name "$language")

    _DEVENV_PREP_COMPOSE_FILES=()
    _DEVENV_PREP_IMAGE=""
    _devenv_resolve_compose_files "$language" _DEVENV_PREP_COMPOSE_FILES _DEVENV_PREP_IMAGE || return 1

    _DEVENV_PREP_CLAUDE_DIR=""
    _DEVENV_PREP_CLAUDE_FILE=""

    local hook
    for hook in $(compgen -A function 2>/dev/null | grep -E '^_devenv_lib_[a-z0-9_]+_hook$' || true); do
        "$hook" "$language" "$_DEVENV_PREP_PROJECT" "$version" || return 1
    done

    _DEVENV_PREP_PORT_ARGS=()
    if [ -n "$ports" ]; then
        IFS=',' read -ra port_list <<< "$ports"
        for port in "${port_list[@]}"; do
            _DEVENV_PREP_PORT_ARGS+=(-p "127.0.0.1:$port:$port")
        done
    fi
    if [ -n "$public_ports" ]; then
        IFS=',' read -ra port_list <<< "$public_ports"
        for port in "${port_list[@]}"; do
            _DEVENV_PREP_PORT_ARGS+=(-p "0.0.0.0:$port:$port")
        done
    fi

    _DEVENV_PREP_GIT_MOUNT=()
    if [ -e "$(pwd)/.git" ]; then
        _DEVENV_PREP_GIT_MOUNT=(-v "$(pwd)/.git:/workspace/.git:ro")
    fi

    _devenv_unload_libs
}

devenv() {
    local language=${1:-golang}
    local version=${2:-dev}
    local ports=${3:-}
    local public_ports=${4:-}

    _devenv_prepare "$language" "$version" "$ports" "$public_ports" || return 1

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
        "${_DEVENV_PREP_PORT_ARGS[@]}" \
        -v "$(pwd):/workspace" \
        "${_DEVENV_PREP_GIT_MOUNT[@]}" \
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

    _devenv_prepare "$language" "$version" "$ports" "$public_ports" || return 1

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
    if [ ${#_DEVENV_PREP_PORT_ARGS[@]} -gt 0 ]; then
        echo "extra ports:    ${_DEVENV_PREP_PORT_ARGS[*]}"
    else
        echo "extra ports:    (none)"
    fi
    echo "workspace:      -v $(pwd):/workspace"
    if [ ${#_DEVENV_PREP_GIT_MOUNT[@]} -gt 0 ]; then
        echo "git mount:      ${_DEVENV_PREP_GIT_MOUNT[*]}"
    fi
}

devenv-connect() {
    local language=${1:-golang}
    _devenv_validate_language "$language" || return 1
    _devenv_check_docker || return 1
    docker exec -it "$(_devenv_container_name "$language")" bash
}

devenv-exec() {
    local language=${1:-golang}
    _devenv_validate_language "$language" || return 1
    shift 1
    if [ $# -eq 0 ]; then
        echo "Usage: devenv-exec [language] <command> [args...]"
        return 1
    fi
    _devenv_check_docker || return 1
    docker exec "$(_devenv_container_name "$language")" "$@"
}

[ -f "$_DEVENV_DIR/shell/completion.sh" ] && source "$_DEVENV_DIR/shell/completion.sh"