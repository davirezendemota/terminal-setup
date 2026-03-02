#!/usr/bin/env bash
set -e

# Dotfiles install script for GitHub Codespaces
# When this script exists, Codespaces does NOT copy dotfiles to $HOME; we do it here.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$PATH"

echo "==> Dotfiles install (Codespaces) from $DOTFILES_DIR"

# --- Copy dotfiles to $HOME (Codespaces only runs the script, does not copy when script exists) ---
for f in .zshrc .zprofile .gitconfig .p10k.zsh; do
  if [ -f "$DOTFILES_DIR/$f" ]; then
    echo "==> Copying $f to \$HOME"
    cp "$DOTFILES_DIR/$f" "$HOME/$f"
  fi
done

# --- Copy .cursor/commands (e.g. /gsync) into $HOME/.cursor ---
if [ -d "$DOTFILES_DIR/.cursor/commands" ]; then
  echo "==> Copying .cursor/commands to \$HOME/.cursor"
  mkdir -p "$HOME/.cursor/commands"
  cp -r "$DOTFILES_DIR/.cursor/commands/"* "$HOME/.cursor/commands/" 2>/dev/null || true
fi

# --- Copy .vscode config to Cursor/VS Code User (for installs outside this workspace) ---
if [ -d "$DOTFILES_DIR/.vscode" ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
  else
    CURSOR_USER="${XDG_CONFIG_HOME:-$HOME/.config}/Cursor/User"
  fi
  if mkdir -p "$CURSOR_USER" 2>/dev/null; then
    for f in settings.json keybindings.json; do
      if [ -f "$DOTFILES_DIR/.vscode/$f" ]; then
        echo "==> Copying .vscode/$f to Cursor User"
        cp "$DOTFILES_DIR/.vscode/$f" "$CURSOR_USER/$f"
      fi
    done
  fi
fi

# --- Install Zsh (Debian/Ubuntu Codespaces image) ---
if ! command -v zsh &>/dev/null; then
  echo "==> Installing zsh..."
  sudo apt-get update -qq
  sudo apt-get install -y zsh
fi

# --- Install Cursor Agent CLI ---
if ! command -v cursor &>/dev/null; then
  echo "==> Installing Cursor Agent CLI..."
  curl -fsSL https://cursor.com/install | bash
else
  echo "==> Cursor CLI already installed."
fi

# --- Set default shell to zsh (if not already) ---
if [ -n "$BASH_VERSION" ] && [ "$(basename "$SHELL")" != "zsh" ]; then
  if command -v zsh &>/dev/null; then
    echo "==> Setting default shell to zsh..."
    sudo chsh -s "$(command -v zsh)" "$(whoami)" || true
  fi
fi

# --- Install Python, pip & pipenv ---
if ! command -v python3 &>/dev/null; then
  echo "==> Installing Python3..."
  sudo apt-get update -qq
  sudo apt-get install -y python3 python3-pip
fi
if ! command -v pipenv &>/dev/null; then
  echo "==> Installing pipenv..."
  pip3 install --user pipenv
fi

# --- Install Node.js & npm (via nvm) ---
if ! command -v node &>/dev/null; then
  echo "==> Installing Node.js via nvm..."
  export NVM_DIR="$HOME/.nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install --lts
fi

# --- Optional: Oh My Zsh (for .zshrc that uses it) ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- Optional: zsh plugins (if .zshrc uses them) ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ ! -d "$ZSH_CUSTOM/plugins/$plugin" ]; then
    echo "==> Installing zsh plugin: $plugin"
    git clone --depth=1 "https://github.com/zsh-users/$plugin.git" "$ZSH_CUSTOM/plugins/$plugin" 2>/dev/null || true
  fi
done

# --- Optional: Powerlevel10k theme (if .zshrc uses it) ---
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  echo "==> Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" 2>/dev/null || true
fi

echo "==> Dotfiles install done. Open a new terminal or run: exec zsh"
