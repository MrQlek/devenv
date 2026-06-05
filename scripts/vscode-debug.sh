devenv-vscode-debug-golang() {
    local force=0
    local arg
    for arg in "$@"; do
        case "$arg" in
            --force|-f) force=1 ;;
            -h|--help)
                cat <<'EOF'
Usage: devenv-vscode-debug-golang [--force]

Writes .vscode/launch.json in the current directory with a remote-attach
configuration for Delve running inside a devenv container on 127.0.0.1:2345.

Run from the host, in the same directory you pass to `devenv`.

Inside the container, start delve with:
    cd /workspace/<your-package> && dlv-debug

Then in VS Code, F5 -> "Attach to dlv in devenv".

Options:
    --force, -f    Overwrite an existing .vscode/launch.json.
EOF
                return 0
                ;;
            *)
                echo "ERROR: unknown argument '$arg' (try --help)" >&2
                return 1
                ;;
        esac
    done

    local target=".vscode/launch.json"
    if [ -e "$target" ] && [ "$force" -ne 1 ]; then
        echo "ERROR: $target already exists. Pass --force to overwrite." >&2
        return 1
    fi

    mkdir -p .vscode || return 1
    cat > "$target" <<'EOF'
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Attach to dlv in devenv",
      "type": "go",
      "request": "attach",
      "mode": "remote",
      "host": "127.0.0.1",
      "port": 2345,
      "substitutePath": [
        { "from": "${workspaceFolder}", "to": "/workspace" }
      ]
    }
  ]
}
EOF
    echo "Wrote $target"
    echo "Next: in the container run 'dlv-debug' from your package dir, then F5 in VS Code."
}
