_devenv_lib_hugo_hook() {
    local language=$1
    local project=$2
    local version=$3
    [[ "$language" == hugo* ]] || return 0
    mkdir -p "$_DEVENV_USER_HOME/.devenv/hugo-mod/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/hugo-cache/$version"
}
