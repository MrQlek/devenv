_devenv_lib_dotnet_hook() {
    local language=$1
    local project=$2
    local version=$3
    [[ "$language" == dotnet* ]] || return 0
    mkdir -p "$_DEVENV_USER_HOME/.devenv/nuget/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/dotnet-tools/$version"
    mkdir -p "$_DEVENV_USER_HOME/.devenv/dotnet-templates/$version"
}
