#!/bin/bash

set -euo pipefail

DEVENV_USER_HOME="$HOME"

usage() {
    echo "Usage: $0 <language> <image-version>"
    echo "  e.g. $0 golang dev"
    exit 1
}

setup_golang() {
    local version=$1
    mkdir -p "$DEVENV_USER_HOME/.devenv/go-mod/$version"
    mkdir -p "$DEVENV_USER_HOME/.devenv/go-cache/$version"
    echo "golang $version environment ready"
}

[ $# -lt 2 ] && usage

language=$1
version=$2

case $language in
    golang) setup_golang "$version" ;;
    *) echo "Unknown language: $language"; exit 1 ;;
esac
