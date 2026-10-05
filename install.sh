#!/usr/bin/env bash
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# install.sh -- set up this machine's shell environment from the shell-config repo.
#
# Idempotent: safe to re-run. It (1) installs the required packages, (2) creates
# symlinks from the home directory into this repo, (3) sets up the module-system
# scaffolding, and (4) creates the GDB test users for passwordless local ssh. Any
# pre-existing *real* file that would be overwritten is backed up to <file>.bak.
#
# Usage:  ./install.sh            # packages + symlinks + scaffolding + gdb users
#         ./install.sh --links    # symlinks + scaffolding only (skip dnf + sudo)
#
# See README.md for what each piece is and its dependencies.

set -euo pipefail

# Resolve the repo root (directory containing this script), regardless of cwd.
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#-----------------------------------------------------------------------------#
# 1. Packages
#-----------------------------------------------------------------------------#

PACKAGES=(
  # Environment Modules -- the `module` command, core to the ~/.software system.
  environment-modules

  # bash completion framework; also where the git completion the prompt/aliases
  # rely on comes from now (we no longer vendor a copy).
  bash-completion

  # git ships git-core, which provides the prompt helper the bashrc sources:
  # /usr/share/git-core/contrib/completion/git-prompt.sh (__git_ps1).
  git

  # Perl + the one non-core module used by bin/module-sync and
  # bin/remove-changelog-from-patch (the rest of their imports are core; the
  # 'perl' meta-package guarantees the split-out stdlib RPMs on Fedora).
  perl perl-boolean

  # Terminal multiplexer (dotfiles/tmux.conf).
  tmux

  # less provides /usr/bin/lesspipe.sh (the bashrc's LESSOPEN) and works with
  # dotfiles/lessfilter; tree + curl are used by aliases / the weather() helper.
  less tree curl
)

install_packages() {
  echo ">> Installing packages (sudo)..."
  sudo dnf install -y "${PACKAGES[@]}"
}

#-----------------------------------------------------------------------------#
# 2. Symlinks
#-----------------------------------------------------------------------------#

# link SRC DEST : symlink DEST -> SRC, backing up an existing real DEST.
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    ln -sfn "$src" "$dest"                      # already a symlink: repoint
  elif [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak"                       # real file: back it up
    echo "   backed up existing $dest -> $dest.bak"
    ln -s "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
  echo "   linked $dest -> $src"
}

create_symlinks() {
  echo ">> Creating symlinks..."

  # Bash config: dropped into ~/.bashrc.d/, which Fedora's default ~/.bashrc
  # sources automatically. Numeric prefixes control load order (the main config
  # before the project switcher). We deliberately do NOT touch ~/.bashrc itself.
  link "$REPO/dotfiles/bashrc.d/10-bashrc.sh"       "$HOME/.bashrc.d/10-bashrc.sh"
  link "$REPO/dotfiles/bashrc.d/20-apb-projects.sh" "$HOME/.bashrc.d/20-apb-projects.sh"

  # tmux + less helpers.
  link "$REPO/dotfiles/tmux.conf"  "$HOME/.tmux.conf"
  link "$REPO/dotfiles/lessfilter" "$HOME/.lessfilter"

  # Environment-Modules config: top-level modulerc + the shared support files.
  link "$REPO/dotfiles/modulerc"                       "$HOME/.modulerc"
  link "$REPO/dotfiles/software/support/module-common"  "$HOME/.software/support/module-common"
  link "$REPO/dotfiles/software/support/module-example" "$HOME/.software/support/module-example"

  # ~/bin helper scripts (link every file the repo tracks under bin/).
  for f in "$REPO"/bin/*; do
    link "$f" "$HOME/bin/$(basename "$f")"
  done
}

#-----------------------------------------------------------------------------#
# 3. Module-system scaffolding
#-----------------------------------------------------------------------------#

# The module system looks for packages under ~/.software/packages/<pkg>/<ver>
# with matching modulefiles under ~/.software/modules/<pkg>/<ver>. The actual
# software is machine-local (not version-controlled); just ensure the dirs exist
# so `module use ~/.software/modules` (from ~/.modulerc) has somewhere to look.
create_module_dirs() {
  echo ">> Ensuring module directories exist..."
  mkdir -p "$HOME/.software/modules" "$HOME/.software/packages"
}

#-----------------------------------------------------------------------------#
# 4. GDB test users
#-----------------------------------------------------------------------------#

# GDB's test suite logs in as alternative local users over ssh (no password) to
# run commands. The bashrc exports GDB_HOST_USERNAME=remote-host and
# GDB_TARGET_USERNAME=remote-target; ~/.ssh/config maps those users @localhost to
# the keys ~/.ssh/id_rsa_remote_{host,target}. Here we create the users (plain
# default account -- home + /bin/bash; key login works despite the locked
# password) and install the matching PUBLIC key into each user's authorized_keys.
# The private/public keys and ~/.ssh/config stay machine-local -- nothing secret
# is read from or written to this repo.
configure_gdb_test_users() {
  echo ">> Setting up GDB test users (sudo)..."
  local role user pub home
  for role in host target; do
    user="remote-$role"
    pub="$HOME/.ssh/id_rsa_remote_${role}.pub"

    if ! id "$user" >/dev/null 2>&1; then
      echo "   creating user $user"
      sudo useradd "$user"
    else
      echo "   user $user already exists"
    fi

    if [[ ! -f "$pub" ]]; then
      echo "   NOTE: $pub not found -- skipping authorized_keys for $user"
      continue
    fi

    home="$(getent passwd "$user" | cut -d: -f6)"
    sudo install -d -m 700 -o "$user" -g "$user" "$home/.ssh"
    if ! sudo grep -qxFf "$pub" "$home/.ssh/authorized_keys" 2>/dev/null; then
      echo "   installing public key into $user's authorized_keys"
      # Read our own public key (as us); tee does the privileged append.
      # shellcheck disable=SC2024
      sudo tee -a "$home/.ssh/authorized_keys" < "$pub" >/dev/null
    fi
    sudo chown "$user:$user" "$home/.ssh/authorized_keys"
    sudo chmod 600 "$home/.ssh/authorized_keys"
  done
}

#-----------------------------------------------------------------------------#
# main
#-----------------------------------------------------------------------------#

main() {
  if [[ "${1:-}" != "--links" ]]; then
    install_packages
  fi
  create_symlinks
  create_module_dirs
  if [[ "${1:-}" != "--links" ]]; then
    configure_gdb_test_users
  fi
  echo
  echo ">> Done. Open a new shell (Fedora's ~/.bashrc sources ~/.bashrc.d/*)."
}

main "$@"
