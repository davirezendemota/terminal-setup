# Terminal tooling: editor + tmux/neovim aliases
# Loaded from terminal-setup via install.sh

if [[ -n "${TERMINAL_SETUP_DIR:-}" && -d "$TERMINAL_SETUP_DIR/terminal/bin" ]]; then
  export PATH="$TERMINAL_SETUP_DIR/terminal/bin:$PATH"
fi

# tmux não repassa COLORTERM por padrão; CLIs (cursor, claude) precisam disso p/ cores
if [[ -n "${TMUX:-}" ]]; then
  export COLORTERM=truecolor
  export FORCE_COLOR=1
  unset NO_COLOR
fi

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
export VISUAL="$EDITOR"

t() {
  if [[ -n "${TMUX:-}" ]]; then
    return 0
  fi
  if ! tmux has-session 2>/dev/null; then
    tmux new
    return
  fi
  local session
  session="$(
    tmux list-sessions -F '#{session_last_attached} #{session_name}' \
      | sort -n \
      | tail -1 \
      | cut -d' ' -f2-
  )"
  tmux attach -t "$session"
}

alias nv='nvim'
alias tfix='tmux-fix'
