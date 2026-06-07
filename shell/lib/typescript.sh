_devenv_lib_typescript_hook() {
    local language=$1
    local project=$2
    local version=$3
    [[ "$language" == typescript* ]] || return 0
    mkdir -p "$_DEVENV_USER_HOME/.devenv/npm-cache/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/expo/$version"
}
