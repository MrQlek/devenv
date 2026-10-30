_devenv_lib_manim_hook() {
    local language=$1
    local project=$2
    local version=$3
    [[ "$language" == manim* ]] || return 0
    mkdir -p "$_DEVENV_USER_HOME/.devenv/manim-uv-cache/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/manim-uv-share/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/manim-uv-bin/$version"
}
