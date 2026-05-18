#!/bin/bash

set -euo pipefail

DEVENV_USER_HOME="$HOME"

usage() {
    echo "Usage: $0 <language> <release>"
    echo "  e.g. $0 golang 1.26"
    exit 1
}

setup_golang() {
    local release=$1
    mkdir -p "$DEVENV_USER_HOME/.dockerdevenv/go-mod/$release"
    mkdir -p "$DEVENV_USER_HOME/.dockerdevenv/go-cache/$release"
    echo "golang $release environment ready"
}

[ $# -lt 2 ] && usage

language=$1
release=$2

case $language in
    golang) setup_golang "$release" ;;
    *) echo "Unknown language: $language"; exit 1 ;;
esac

