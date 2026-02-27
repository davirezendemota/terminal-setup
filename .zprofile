# Homebrew (macOS only; safe no-op on Linux/Codespaces)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
# VS Code / Cursor CLI path (when installed via install script)
export PATH="$PATH:$HOME/.local/bin"
