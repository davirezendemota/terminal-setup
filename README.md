# Dotfiles (GitHub Codespaces)

Configuração de dotfiles para uso em **GitHub Codespaces**. Também pode ser usada localmente (macOS/Linux).

## O que é configurado

- **Zsh** – shell padrão
- **Oh My Zsh** – framework Zsh com tema Powerlevel10k
- **Plugins** – `zsh-autosuggestions`, `zsh-syntax-highlighting`
- **Cursor Agent CLI** – instalado via `curl https://cursor.com/install | bash`
- **Git** – aliases e opções (veja abaixo)
- **.zshrc / .zprofile** – baseados na sua máquina local, com `$HOME` e compatível com Codespaces
- **.cursor/commands** – comandos Cursor `/gsync` e `/gsync_current` (commits atômicos, conventional commits; gsync cria branch, gsync_current faz push na branch atual)
- **.vscode** – `settings.json` e `keybindings.json` (explorer, editor, atalhos, Cursor composer, vim-style). Ao abrir este repo no VS Code/Cursor, as configs do workspace são aplicadas; o `install.sh` também copia para o User global.
- **Terminal** – Neovim, tmux e aliases de shell (`t`, `nv`)

## Ativar no GitHub Codespaces

1. No GitHub: **Settings** → **Codespaces**.
2. Em **Dotfiles**, escolha este repositório no dropdown.
3. Marque **Automatically install dotfiles**.
4. Crie um novo codespace; o repositório será clonado, os dotfiles copiados para `$HOME` e o `install.sh` executado.

## Instalação do Cursor Agent CLI

O script `install.sh` já instala o Cursor CLI:

```bash
curl -fsSL https://cursor.com/install | bash
```

Para instalar manualmente (por exemplo, em outra máquina), use o comando acima.

## Git aliases (copiados do seu .gitconfig)

| Alias    | Comando |
|----------|--------|
| `glo`    | `git log --oneline` |
| `gwip`   | add ., commit "wip", push |
| `gunwip` | reset --soft HEAD~1 e unstage |
| `gfwip`  | add ., commit "wip", push -f |
| `gclean` | `git clean -fd` (exceto `*.env*`) |

## Estrutura do repositório

- `install.sh` – script executado pelo Codespaces (instala zsh, Cursor CLI, Oh My Zsh, plugins, p10k)
- `.zshrc` – configuração Zsh
- `.zprofile` – profile (Homebrew no macOS; PATH no Linux)
- `.p10k.zsh` – tema Powerlevel10k
- `.gitconfig` – user, init, core e aliases
- `.cursor/commands/gsync.md` – comando `/gsync` do Cursor (regras de commit e push, cria branch)
- `.cursor/commands/gsync_current.md` – comando `/gsync_current` do Cursor (push na branch atual)
- `.vscode/settings.json` – configurações do workspace (e copiado para Cursor User pelo install)
- `.vscode/keybindings.json` – atalhos (agent, terminal, vim-style splits, etc.)
- `terminal/nvim/init.lua` – config Neovim
- `terminal/tmux.conf` – config tmux
- `terminal/zsh/terminal.zsh` – aliases `t`/`nv` e `EDITOR`
- `terminal/iterm2/` – prefs iTerm2 (macOS, opcional)

## Uso local (macOS / Linux)

### Só terminal (nvim + tmux) — não sobrescreve seu `.zshrc`

```bash
git clone git@github.com:davirezendemota/dotfiles.git ~/Documents/dotfiles
cd ~/Documents/dotfiles
./install.sh --terminal-only --terminal-deps
source ~/.zshrc
```

### Instalação completa (copia `.zshrc`, Oh My Zsh, Cursor CLI, etc.)

```bash
git clone git@github.com:davirezendemota/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --full --terminal-deps
exec zsh
```

### iTerm2 (macOS, opcional)

1. iTerm2 → Settings → General → Preferences
2. **Load preferences from a custom folder or URL**
3. Aponte para: `<repo>/terminal/iterm2`

Recomendação: em Codespaces deixe o GitHub gerenciar clone e cópia; localmente use `--terminal-only` se já tiver um `.zshrc` customizado.
