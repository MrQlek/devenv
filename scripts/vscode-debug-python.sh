devenv-vscode-debug-python() {
    local force=0
    local arg
    for arg in "$@"; do
        case "$arg" in
            --force|-f) force=1 ;;
            -h|--help)
                cat <<'EOF'
Usage: devenv-vscode-debug-python [--force]

Writes .vscode/launch.json in the current directory with a remote-attach
configuration for debugpy running inside a devenv container on 127.0.0.1:5678.

Run from the host, in the same directory you pass to `devenv`.

Inside the container, start debugpy with one of:
    py-debug app.py                         # uses system Python
    py-debug-uv app.py                      # uses project's uv venv
    uv run --with debugpy python -m debugpy --listen 0.0.0.0:5678 --wait-for-client app.py

Then in VS Code, F5 -> "Attach to debugpy in devenv".

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
      "name": "Attach to debugpy in devenv",
      "type": "debugpy",
      "request": "attach",
      "connect": {
        "host": "127.0.0.1",
        "port": 5678
      },
      "pathMappings": [
        { "localRoot": "${workspaceFolder}", "remoteRoot": "/workspace" }
      ]
    }
  ]
}
EOF
    echo "Wrote $target"
    echo "Next: in the container run 'py-debug-uv app.py' from your project dir, then F5 in VS Code."
}
