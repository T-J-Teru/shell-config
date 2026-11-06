# shell-config

Bash shell environment for a Fedora workstation. Licensed GPLv3.

## Repo layout

```
install.sh          # idempotent installer: packages + symlinks + scaffolding
bin/                # ~/bin helper scripts (symlinked by install.sh)
dotfiles/           # config files symlinked into ~
  bashrc.d/         # dropped into ~/.bashrc.d/ (Fedora's ~/.bashrc sources it)
  lessfilter        # -> ~/.lessfilter
  tmux.conf         # -> ~/.tmux.conf
  modulerc          # -> ~/.modulerc
  software/support/ # -> ~/.software/support/
```

## Conventions

- **install.sh** resolves its own directory (`REPO=...`) so it works from any cwd. Uses `set -euo pipefail`. Supports `--links` to skip dnf/sudo steps.
- **Symlinks are explicit** in `create_symlinks()` -- no stow, no glob-to-home. Each link is a deliberate line.
- **Numeric prefixes** on bashrc.d files control load order: `10-bashrc.sh` (main config), `20-apb-projects.sh` (project switcher), `99-*-setup.sh` (late-loading env snippets like cargo, claude). Order between files sharing a prefix doesn't matter.
- **Machine-local files** like `99-claude-setup.sh` and `env.sh` live in `~/.bashrc.d/` on each machine but are NOT in this repo.
- **GPL headers** go on `install.sh` and every `bin/` script. Do NOT add headers to dotfile configs (bashrc.d files, tmux.conf, lessfilter, modulerc).
- **Third-party files** that aren't ours get a provenance comment (where it came from, license) instead of a GPL header.

## Key technical details

- The prompt uses **bash-preexec** (`preexec_functions`/`precmd_functions` arrays) for command timing. The library is at `/usr/libexec/bash-preexec/bash-preexec.sh`; the bashrc sources it directly. Do NOT install `bash-preexec-all-users`.
- The **Environment Modules** system (`module load/unload`) looks under `~/.software/packages/` and `~/.software/modules/`. Modulefiles can also go in `~/.modules/`. None of these directories are version-controlled.
- `~/.ssh/config` is deliberately NOT version-controlled (contains internal hostnames/IPs).
- The `addpath` function (defined in 10-bashrc.sh) accepts `--quiet` to suppress errors for paths that may not exist (e.g. ccache).

## When editing

- Test bashrc changes by sourcing in a subshell: `bash -c 'source ~/.bashrc.d/10-bashrc.sh'` or opening a new terminal.
- If adding a new package, add it to the `PACKAGES` array in install.sh with a comment explaining what uses it.
- If adding a new dotfile, add an explicit `link` call in `create_symlinks()`.
- If adding a new `bin/` script, the `for f in "$REPO"/bin/*` loop picks it up automatically -- just add the GPL header.
