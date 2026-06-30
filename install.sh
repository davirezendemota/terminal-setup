#!/usr/bin/env bash
set -e

# terminal-setup install script for GitHub Codespaces and local machines.
# When this script exists, Codespaces does NOT copy dotfiles to $HOME; we do it here.

TERMINAL_SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"
ZSHRC="${ZSHRC:-$HOME/.zshrc}"
TERMINAL_MARKER_BEGIN="# >>> terminal-setup BEGIN >>>"
TERMINAL_MARKER_END="# <<< terminal-setup END >>>"

FULL_INSTALL=false
TERMINAL_ONLY=false
INSTALL_TERMINAL_DEPS=false

usage() {
  cat <<EOF
Usage: ./install.sh [options]

Options:
  --full            Copy shell dotfiles to \$HOME (default in Codespaces)
  --terminal-only   Only install nvim/tmux symlinks and shell integration
  --terminal-deps   Install neovim and tmux if missing
  -h, --help
EOF
}

is_codespaces() {
  [ -n "${CODESPACES:-}" ] || [ -n "${CODESPACE_NAME:-}" ] || [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full) FULL_INSTALL=true; shift ;;
      --terminal-only) TERMINAL_ONLY=true; shift ;;
      --terminal-deps) INSTALL_TERMINAL_DEPS=true; shift ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
  done

  if is_codespaces; then
    FULL_INSTALL=true
  fi
}

install_terminal_deps() {
  if command -v nvim >/dev/null 2>&1 && command -v tmux >/dev/null 2>&1; then
    echo "==> neovim and tmux already installed"
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      if ! command -v brew >/dev/null 2>&1; then
        echo "==> Homebrew not found; install neovim/tmux manually or install Homebrew"
        return 1
      fi
      echo "==> Installing neovim and tmux (Homebrew)..."
      brew install neovim tmux
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        echo "==> Installing neovim and tmux (apt)..."
        sudo apt-get update -qq
        sudo apt-get install -y neovim tmux
      elif command -v dnf >/dev/null 2>&1; then
        echo "==> Installing neovim and tmux (dnf)..."
        sudo dnf install -y neovim tmux
      elif command -v pacman >/dev/null 2>&1; then
        echo "==> Installing neovim and tmux (pacman)..."
        sudo pacman -S --needed neovim tmux
      else
        echo "==> Could not detect package manager; install neovim and tmux manually"
        return 1
      fi
      ;;
    *)
      echo "==> Unsupported OS for --terminal-deps"
      return 1
      ;;
  esac
}

install_terminal_configs() {
  local term_dir="$TERMINAL_SETUP_DIR/terminal"
  if [ ! -d "$term_dir" ]; then
    echo "==> No terminal/ directory found; skipping nvim/tmux setup"
    return 0
  fi

  echo "==> Installing terminal configs (nvim, tmux)"
  mkdir -p "$HOME/.config"
  ln -sfn "$term_dir/nvim" "$HOME/.config/nvim"
  ln -sfn "$term_dir/tmux.conf" "$HOME/.tmux.conf"
  echo "    Linked $HOME/.config/nvim -> $term_dir/nvim"
  echo "    Linked $HOME/.tmux.conf -> $term_dir/tmux.conf"
}

remove_terminal_zsh_block() {
  if [ ! -f "$ZSHRC" ] || ! grep -qF "$TERMINAL_MARKER_BEGIN" "$ZSHRC" 2>/dev/null; then
    return 0
  fi

  awk -v begin="$TERMINAL_MARKER_BEGIN" -v end="$TERMINAL_MARKER_END" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$ZSHRC" > "${ZSHRC}.tmp"
  mv "${ZSHRC}.tmp" "$ZSHRC"
}

remove_legacy_terminal_lines() {
  if [ ! -f "$ZSHRC" ]; then
    return 0
  fi

  grep -v 'Documents/terminal-config/zsh/terminal.zsh' "$ZSHRC" |
    grep -v 'Documents/dotfiles/terminal/zsh/terminal.zsh' "$ZSHRC" |
    grep -v '^# Terminal configs (tmux, neovim, editor)$' |
    grep -v '^# >>> terminal-config BEGIN >>>$' |
    grep -v '^# <<< terminal-config END >>>$' |
    grep -v '^# >>> dotfiles terminal BEGIN >>>$' |
    grep -v '^# <<< dotfiles terminal END >>>$' |
    grep -v '^export TERMINAL_CONFIG_DIR=' |
    grep -v '^export DOTFILES_DIR=' |
    grep -v 'TERMINAL_CONFIG_DIR/terminal/zsh/terminal.zsh' |
    grep -v 'DOTFILES_DIR/terminal/zsh/terminal.zsh' |
    grep -v '^# Path to dotfiles repo' > "${ZSHRC}.tmp" || true
  mv "${ZSHRC}.tmp" "$ZSHRC"
}

ensure_terminal_setup_in_zshrc() {
  touch "$ZSHRC"
  remove_terminal_zsh_block
  remove_legacy_terminal_lines

  if grep -q 'export TERMINAL_SETUP_DIR=' "$ZSHRC" 2>/dev/null; then
    sed -i.bak "s|^export TERMINAL_SETUP_DIR=.*|export TERMINAL_SETUP_DIR=\"$TERMINAL_SETUP_DIR\"|" "$ZSHRC"
    rm -f "${ZSHRC}.bak"
  else
    cat >>"$ZSHRC" <<EOF

# Path to terminal-setup repo (set by install.sh)
export TERMINAL_SETUP_DIR="$TERMINAL_SETUP_DIR"
EOF
  fi

  if ! grep -qF "$TERMINAL_MARKER_BEGIN" "$ZSHRC" 2>/dev/null; then
    cat >>"$ZSHRC" <<EOF

$TERMINAL_MARKER_BEGIN
[[ -f "\$TERMINAL_SETUP_DIR/terminal/zsh/terminal.zsh" ]] && source "\$TERMINAL_SETUP_DIR/terminal/zsh/terminal.zsh"
$TERMINAL_MARKER_END
EOF
  fi

  echo "==> Updated $ZSHRC with TERMINAL_SETUP_DIR and terminal integration"
}

copy_shell_dotfiles() {
  for f in .zshrc .zprofile .gitconfig .p10k.zsh; do
    if [ -f "$TERMINAL_SETUP_DIR/$f" ]; then
      echo "==> Copying $f to \$HOME"
      cp "$TERMINAL_SETUP_DIR/$f" "$HOME/$f"
    fi
  done

  if [ -f "$HOME/.zshrc" ]; then
    sed -i.bak "s|^export TERMINAL_SETUP_DIR=.*|export TERMINAL_SETUP_DIR=\"$TERMINAL_SETUP_DIR\"|" "$HOME/.zshrc" 2>/dev/null || true
    rm -f "${HOME}/.zshrc.bak"
  fi
}

install_terminal_title() {
  if [ -f "$ZSHRC" ] && ! grep -q '_set_terminal_title' "$ZSHRC" 2>/dev/null; then
    echo "==> Adding terminal title to .zshrc"
    cat >>"$ZSHRC" <<'TERMINAL_TITLE_ZSH'
# Terminal title (terminal-setup)
_set_terminal_title() {
  local title="${HAWKOS_TERMINAL_TITLE:-HawkOS — pronto}"
  printf '\033]0;%s\007' "$title"
}
if type add-zsh-hook &>/dev/null; then
  add-zsh-hook precmd _set_terminal_title
else
  precmd_functions+=(_set_terminal_title)
fi
TERMINAL_TITLE_ZSH
  fi

  if [ ! -f "$HOME/.bashrc" ]; then
    touch "$HOME/.bashrc"
  fi
  if ! grep -q '_set_terminal_title' "$HOME/.bashrc" 2>/dev/null; then
    echo "==> Adding terminal title to .bashrc"
    cat >>"$HOME/.bashrc" <<'TERMINAL_TITLE_BASH'
# Terminal title (terminal-setup)
_set_terminal_title() {
  local title="${HAWKOS_TERMINAL_TITLE:-HawkOS — pronto}"
  printf '\033]0;%s\007' "$title"
}
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_set_terminal_title"
TERMINAL_TITLE_BASH
  fi
}

install_cursor_commands() {
  if [ -d "$TERMINAL_SETUP_DIR/.cursor/commands" ]; then
    echo "==> Copying .cursor/commands to \$HOME/.cursor"
    mkdir -p "$HOME/.cursor/commands"
    cp -r "$TERMINAL_SETUP_DIR/.cursor/commands/"* "$HOME/.cursor/commands/" 2>/dev/null || true
  fi
}

install_vscode_cursor_user() {
  if [ -d "$TERMINAL_SETUP_DIR/.vscode" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
    else
      CURSOR_USER="${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User"
    fi
    if mkdir -p "$CURSOR_USER" 2>/dev/null; then
      for f in settings.json keybindings.json; do
        if [ -f "$TERMINAL_SETUP_DIR/.vscode/$f" ]; then
          echo "==> Copying .vscode/$f to Cursor User"
          cp "$TERMINAL_SETUP_DIR/.vscode/$f" "$CURSOR_USER/$f"
        fi
      done
    fi
  fi
}

install_shell_stack() {
  if ! command -v zsh >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
    echo "==> Installing zsh..."
    sudo apt-get update -qq
    sudo apt-get install -y zsh
  fi

  if ! command -v cursor &>/dev/null; then
    echo "==> Installing Cursor Agent CLI..."
    curl -fsSL https://cursor.com/install | bash || true
  else
    echo "==> Cursor CLI already installed."
  fi

  if [ -n "$BASH_VERSION" ] && [ "$(basename "$SHELL")" != "zsh" ] && command -v zsh &>/dev/null; then
    echo "==> Setting default shell to zsh..."
    sudo chsh -s "$(command -v zsh)" "$(whoami)" || true
  fi

  if ! command -v python3 &>/dev/null && command -v apt-get &>/dev/null; then
    echo "==> Installing Python3..."
    sudo apt-get update -qq
    sudo apt-get install -y python3 python3-pip
  fi
  if ! command -v pipenv &>/dev/null && command -v pip3 &>/dev/null; then
    echo "==> Installing pipenv..."
    pip3 install --user pipenv || true
  fi

  if ! command -v node &>/dev/null; then
    echo "==> Installing Node.js via nvm..."
    export NVM_DIR="$HOME/.nvm"
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
      curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    nvm install --lts || true
  fi

  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "==> Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
    if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
      echo "==> Installing zsh plugin: $plugin"
      git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin" 2>/dev/null || true
    fi
  done

  if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
    echo "==> Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k" 2>/dev/null || true
  fi
}

main() {
  parse_args "$@"

  echo "==> terminal-setup install from $TERMINAL_SETUP_DIR"

  if $INSTALL_TERMINAL_DEPS; then
    install_terminal_deps || true
  fi

  install_terminal_configs

  if $TERMINAL_ONLY; then
    ensure_terminal_setup_in_zshrc
    echo "==> Terminal-only install done. Run: source ~/.zshrc"
    exit 0
  fi

  if $FULL_INSTALL; then
    copy_shell_dotfiles
    install_terminal_title
    install_cursor_commands
    install_vscode_cursor_user
    install_shell_stack
  else
    ensure_terminal_setup_in_zshrc
    install_cursor_commands
    install_vscode_cursor_user
  fi

  echo "==> terminal-setup install done. Open a new terminal or run: exec zsh"
}

main "$@"
