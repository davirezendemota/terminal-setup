# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"

# Theme (powerlevel10k if installed by install.sh)
ZSH_THEME="${ZSH_THEME:-powerlevel10k/powerlevel10k}"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# --- Aliases ---
# Docker: limpar todo o sistema (containers, imagens, volumes, build cache)
alias docker-prune='docker system prune -a --volumes -f'

# Powerlevel10k config (if present)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# NVM (optional)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# PATH
export PATH="$HOME/.local/bin:$PATH"
# Homebrew (macOS; no-op on Codespaces if not installed)
if [[ -x /opt/homebrew/bin/brew ]]; then
  export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
fi

# Workspace paths (optional; set in Codespaces if needed)
[[ -n "$EBOS_PATH" ]] || export EBOS_PATH="${EBOS_PATH:-$HOME/workspace/ebos-rmconsult}"
[[ -n "$HAWKOS_PATH" ]] || export HAWKOS_PATH="${HAWKOS_PATH:-$HOME/workspace/hawkos-rmconsult}"
