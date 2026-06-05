if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -U +X bashcompinit && bashcompinit
fi

_devenv_list_images() {
    docker images --format '{{.Repository}} {{.Tag}}' 2>/dev/null \
        | awk '$1 ~ /^devenv-image-/ && $2 != "<none>" {
                   sub(/^devenv-image-/, "", $1); print $1, $2
               }'
}

_devenv_complete() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local images
    images=$(_devenv_list_images)

    case $COMP_CWORD in
        1)
            local langs
            langs=$(echo "$images" | awk '{print $1}' | sort -u)
            COMPREPLY=($(compgen -W "$langs" -- "$cur"))
            ;;
        2)
            local lang=${COMP_WORDS[1]}
            local tags
            tags=$(echo "$images" | awk -v l="$lang" '$1 == l {print $2}' | sort -u)
            COMPREPLY=($(compgen -W "$tags" -- "$cur"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

_devenv_complete_running() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    if [ "$COMP_CWORD" -eq 1 ]; then
        local prefix="devenv-$(_devenv_project_slug)-"
        local names
        names=$(docker ps --filter "name=$prefix" --format '{{.Names}}' 2>/dev/null \
                | sed "s|^$prefix||")
        COMPREPLY=($(compgen -W "$names" -- "$cur"))
    else
        COMPREPLY=()
    fi
}

complete -F _devenv_complete         devenv devenv-inspect
complete -F _devenv_complete_running devenv-connect devenv-exec
