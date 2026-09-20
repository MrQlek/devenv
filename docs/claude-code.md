# Claude Code integration

The `*-claude` image variants (`golang-claude`, `python-claude`, `typescript-claude`, `hugo-claude`, `dotnet-claude`) extend their base image with the Claude Code CLI preinstalled. Configuration, credentials, and session state are mounted from the host so they survive container restarts.

## Mounts and environment

| Host path | Container path | Purpose |
|---|---|---|
| `~/.devenv/claude/projects/<project>/` | `/home/devuser/.claude/` | Per-project Claude config, hooks, MCP servers |
| `~/.devenv/claude/projects/<project>.json` | `/home/devuser/.claude.json` | Claude's per-project state file |
| `$ANTHROPIC_API_KEY` (env) | `$ANTHROPIC_API_KEY` (env) | API key, if set on the host |

The `<project>` name is derived from the absolute path of your current working directory, with slashes replaced by dashes. So `/home/alice/code/myapp` becomes `home-alice-code-myapp`. This guarantees a unique config per project tree.

## First-run config scope prompt

The first time you run `devenv <lang>-claude` in a directory that has no existing project config, you're prompted to choose how to scope the configuration:

```
No Claude config found for project: <project>
  1) Project-specific config
  2) Shared per-language (<lang>-claude)
  3) Shared globally
Choose [1/2/3]:
```

- **Project-specific (1):** A fresh `~/.devenv/claude/projects/<project>/` directory is created. Nothing is shared with other projects.
- **Per-language (2):** A symlink is created from the project dir to `~/.devenv/claude/languages/<lang>-claude/`. Any settings, MCP servers, or hooks written by Claude in this session persist into _every other project_ that selected the same per-language scope.
- **Globally shared (3):** A symlink to `~/.devenv/claude/shared/`. Shared across all projects regardless of language.

The warnings printed for options 2 and 3 are intentional — Claude can write arbitrary settings into the mounted config dir during a session, and shared scopes propagate those writes everywhere.

The choice is sticky per project: once a project's symlink/directory exists, you are not re-prompted.

## Layout under `~/.devenv/claude/`

```
~/.devenv/claude/
├── projects/
│   ├── <project-a>/       # either a real dir (project scope) or a symlink (shared scopes)
│   ├── <project-a>.json
│   ├── <project-b>/
│   └── <project-b>.json
├── languages/
│   ├── golang-claude/     # populated only if a project chose per-language scope
│   ├── golang-claude.json
│   ├── python-claude/
│   └── python-claude.json
└── shared/                # populated only if a project chose global scope
    └── shared.json
```

Permissions are `700` on directories and `600` on the `.json` state files.

## API key — security note

> Passing `ANTHROPIC_API_KEY` via environment variable exposes it to anyone who can run `docker inspect <container>`, to `/proc/<pid>/environ` of every process inside the container, and to any binary Claude spawns.
>
> Prefer `claude login` inside the container on first use — the resulting OAuth credentials are written under `/home/devuser/.claude/`, which is mounted from `~/.devenv/claude/projects/<project>/`, so they persist across container restarts.
>
> Reserve the env-var path for non-interactive or scripted runs where browser-based login is not possible.

## Related

- [building-images.md](building-images.md) — how the `*-claude` images are built and versioned.
- [secrets.md](secrets.md) — hiding host files from anything running in the container (including Claude).
