_devenv_lib_golang_hook() {
    local language=$1
    local project=$2
    local version=$3
    [[ "$language" == golang* ]] || return 0
    mkdir -p "$_DEVENV_USER_HOME/.devenv/go-mod/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/go-cache/$version"
}
