# Terminal tooling: editor + tmux/neovim aliases
# Loaded from dotfiles via install.sh

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
export VISUAL="$EDITOR"

alias t='tmux'
alias nv='nvim'
