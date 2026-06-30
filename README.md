# terminal-setup

Configuração de terminal e shell para **GitHub Codespaces** e uso local (macOS/Linux).

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

## Instalador

O instalador principal é o **`install.py`** (Python 3, stdlib only). O `install.sh` é um wrapper para compatibilidade com GitHub Codespaces.

| Modo | Comando | O que faz |
|------|---------|-----------|
| **Local** (padrão) | `python3 install.py` | nvim/tmux, symlinks, integração no `.zshrc`, Cursor commands |
| **Codespaces** | `python3 install.py --codespaces` | tudo acima + copia dotfiles, Oh My Zsh, Cursor CLI, nvm, etc. |
| Sem deps | `python3 install.py --skip-deps` | local sem instalar neovim/tmux |

No Codespaces, o `install.sh` detecta o ambiente e roda `--codespaces` automaticamente.

## Ativar no GitHub Codespaces

1. No GitHub: **Settings** → **Codespaces**.
2. Em **Dotfiles**, escolha este repositório (`terminal-setup`) no dropdown.
3. Marque **Automatically install dotfiles**.
4. Crie um novo codespace; o repositório será clonado e o `install.sh` → `install.py --codespaces` executado.

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

- `install.py` – instalador principal (modo local por padrão)
- `install.sh` – wrapper para Codespaces (delega ao `install.py`)
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

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/Documents/terminal-setup
cd ~/Documents/terminal-setup
python3 install.py
source ~/.zshrc
```

Não sobrescreve seu `.zshrc` — só adiciona o bloco `terminal-setup` e os symlinks.

### Instalação completa (copia `.zshrc`, Oh My Zsh, Cursor CLI, etc.)

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/terminal-setup
cd ~/terminal-setup
python3 install.py --codespaces
exec zsh
```

### iTerm2 (macOS, opcional)

1. iTerm2 → Settings → General → Preferences
2. **Load preferences from a custom folder or URL**
3. Aponte para: `<repo>/terminal/iterm2`

Recomendação: em Codespaces deixe o GitHub gerenciar clone e cópia; localmente use `python3 install.py` (modo local padrão).
