devenv-vscode-debug-typescript() {
    local force=0
    local arg
    for arg in "$@"; do
        case "$arg" in
            --force|-f) force=1 ;;
            -h|--help)
                cat <<'EOF'
Usage: devenv-vscode-debug-typescript [--force]

Writes .vscode/launch.json in the current directory with a remote-attach
configuration for the Node inspector running inside a devenv container on
127.0.0.1:9229.

Run from the host, in the same directory you pass to `devenv`.

Inside the container, start a debugger session with one of:
    ts-debug dist/app.js                    # tsc compile + node debug (recommended for TS)
    node-debug app.js                       # plain JavaScript
    tsx-debug app.ts                        # tsx (advanced; uses worker threads)
    node --inspect-brk=0.0.0.0:9229 <file>  # full form

Then in VS Code, F5 -> "Attach to Node in devenv".

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
      "name": "Attach to Node in devenv",
      "type": "node",
      "request": "attach",
      "address": "127.0.0.1",
      "port": 9229,
      "localRoot": "${workspaceFolder}",
      "remoteRoot": "/workspace",
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
EOF
    echo "Wrote $target"
    echo "Next: in the container run 'ts-debug dist/app.js' (after 'tsc') from your project dir, then F5 in VS Code."
}
