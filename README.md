# shell-config

Personal **shell** configuration (bash), a small **Environment-Modules** software
system, and assorted **utility scripts**, version-controlled and installed by
`install.sh`. The repo holds the **real files**; the home directory gets
**symlinks** pointing back into it. Edit files here, not the symlinks.

The repo can live anywhere — `install.sh` resolves its own location at runtime and
points every symlink back into wherever it's checked out.

## Layout

```
shell-config/
├── README.md
├── install.sh                          # idempotent: packages + symlinks + scaffolding + gdb users
├── bin/                                -> ~/bin/<name>
│   ├── module-sync                     # regenerate modulefiles from installed packages (perl)
│   ├── upto_core.pl                    # worker for the `upto`/`jmp` bash function (perl)
│   ├── remove-changelog-from-patch     # strip ChangeLog hunks from a patch (perl)
│   ├── jmake                           # parallel make wrapper (bash)
│   ├── script                          # `script` wrapper that marks the shell (bash)
│   └── rename                          # third-party (Larry Wall / Robin Barker) — see note in file
└── dotfiles/
    ├── bashrc.d/
    │   ├── 10-bashrc.sh                -> ~/.bashrc.d/10-bashrc.sh   (main bash config)
    │   └── 20-apb-projects.sh          -> ~/.bashrc.d/20-apb-projects.sh  (`prj` project switcher)
    ├── tmux.conf                       -> ~/.tmux.conf
    ├── lessfilter                      -> ~/.lessfilter
    ├── modulerc                        -> ~/.modulerc
    └── software/support/
        ├── module-common              -> ~/.software/support/module-common
        └── module-example             -> ~/.software/support/module-example
```

## Install

```bash
git clone <this-repo> shell-config     # clone it wherever you like
cd shell-config
./install.sh            # installs packages (sudo), symlinks, module dirs, GDB test users
# open a new shell
```

Re-running is safe. Use `./install.sh --links` to (re)create symlinks and the module
directories only, skipping `dnf` and the privileged GDB-user step.

## How it fits together

- **Bash:** we don't touch `~/.bashrc` — Fedora's default sources `~/.bashrc.d/*`,
  so we drop our files in there (`10-bashrc.sh`, then `20-apb-projects.sh`; numeric
  prefixes set load order). The git prompt comes from git-core's
  `git-prompt.sh`; git completion from the `bash-completion` package.
- **Module system:** `~/.modulerc` adds `~/.software/modules` to the module path;
  software lives in `~/.software/packages/<pkg>/<ver>/` with matching modulefiles in
  `~/.software/modules/<pkg>/<ver>` that source `module-common` → `basic_package_setup`
  (auto-wires PATH/MANPATH/PKG_CONFIG_PATH/… from the package dir). `module-sync`
  regenerates modulefiles from installed packages.

## Dependencies & notes

Packages installed by `install.sh` (Fedora): `environment-modules`,
`bash-completion`, `git`, `perl`, `perl-boolean`, `tmux`, `less`, `tree`, `curl`.

- **Claude keys** — the bashrc intentionally does *not* set these; they live in the
  machine-local `~/.config/claude-code-vertex/env.sh` (loaded by the pre-existing
  `~/.bashrc.d/claude-setup.sh`). That secrets file is never version-controlled.
- **Module software** — `~/.software/{modules,packages}` are created empty; the
  actual installed software is machine-local and not tracked.
- **GDB test users** — `install.sh` creates `remote-host` / `remote-target` (plain
  `useradd` defaults) and installs the matching public key from
  `~/.ssh/id_rsa_remote_{host,target}.pub` into each user's `authorized_keys`, so
  GDB's test suite can `ssh` to them on `localhost` without a password. The keys and
  `~/.ssh/config` stay machine-local — nothing secret is read from or written to
  this repo.

## License

Licensed under the GNU General Public License, version 3 or later — see
[LICENSE](LICENSE). The `bin/` scripts I wrote and `install.sh` carry the GPLv3
license-grant header; the shell/module/tmux config under `dotfiles/` is left
unheadered.

Exception: `bin/rename` is a third-party script (Larry Wall's original via Robin
Barker), distributed "under the same terms as Perl". It keeps its own notice and
does not carry the repo header — see the note at the top of that file.
