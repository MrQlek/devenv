_devenv_lib_python_hook() {
    local language=$1
    local project=$2
    local version=$3
    [[ "$language" == python* ]] || return 0
    mkdir -p "$_DEVENV_USER_HOME/.devenv/uv-cache/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/uv-share/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/uv-bin/$version"
}
