# terminal-setup

Configuração de terminal e shell para **GitHub Codespaces**, **macOS local** e **servidores remotos**.

## Workflow (Mac + servidores)

**iTerm2 no Mac** gerencia hosts; **tmux em cada host** gerencia sessões e abas.

```
Mac (iTerm2)                    Host remoto
┌─────────────────────┐         ┌──────────────────────────┐
│ Tab: prod    → ssh  │ ──────► │ tmux sessão              │
│ Tab: staging → ssh  │ ──────► │   ├─ aba: api            │
│ Tab: dev     → ssh  │ ──────► │   └─ aba: logs           │
└─────────────────────┘         └──────────────────────────┘
```

| Onde | Papel |
|------|-------|
| **iTerm2 (Mac)** | Uma tab ou janela por host; perfil/título com nome do servidor |
| **tmux (no host)** | Sessões que sobrevivem a disconnect; abas e panes dentro de cada sessão |
| **Este repo** | Mesma config (`tmux`, nvim, zsh) no Mac e em todos os servidores |

### Fluxo rápido

1. Abrir tab no iTerm2 para o host → `ssh meu-servidor`
2. `t` — entra na última sessão tmux ou cria uma nova
3. Trabalhar com abas/panes (`Ctrl+s` + `n`/`h`/`v` — ver [atalhos](#atalhos-tmux))
4. `Ctrl+d` — detach (sessão continua no servidor)
5. Reconectar: `ssh` → `t`

Instalar o repo **no Mac e em cada servidor** com `python3 install.py`.

## O que é configurado

- **Zsh** – shell padrão
- **Oh My Zsh** – framework Zsh com tema Powerlevel10k
- **Plugins** – `zsh-autosuggestions`, `zsh-syntax-highlighting`
- **Cursor Agent CLI** – instalado via `curl https://cursor.com/install | bash`
- **Git** – aliases e opções (veja abaixo)
- **.zshrc / .zprofile** – baseados na sua máquina local, com `$HOME` e compatível com Codespaces
- **.cursor/commands** – comandos Cursor `/gsync` e `/gsync_current` (commits atômicos, conventional commits; gsync cria branch, gsync_current faz push na branch atual)
- **.vscode** – `settings.json` e `keybindings.json` (explorer, editor, atalhos, Cursor composer, vim-style). Ao abrir este repo no VS Code/Cursor, as configs do workspace são aplicadas; o `install.sh` também copia para o User global.
- **Terminal** – Neovim, tmux e aliases de shell (`t`, `nv`, `tfix`)

## Atalhos tmux

Prefix padrão: **`Ctrl+s`** (salvo onde indicado).

| Atalho | Ação |
|--------|------|
| `t` (shell) | Attach na última sessão ou cria nova |
| `Ctrl+s` + `n` | Nova aba (window) |
| `Ctrl+s` + `S` | Nova sessão |
| `Ctrl+s` + `h` / `v` | Split horizontal / vertical |
| `Ctrl+s` + `w` | Fechar pane (confirma) |
| `Ctrl+s` + `x` | Fechar aba (confirma) |
| `Ctrl+s` + `q` | Apagar sessão (confirma; troca p/ outra se existir) |
| `Ctrl+d` | Detach (sessão continua rodando) |
| `Ctrl+n` | Próxima aba |
| `Ctrl+h/j/k/l` | Navegar panes / nvim (vim-tmux-navigator) |
| `Ctrl+s` + `r` | Reload config |

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
- `terminal/bin/` – `tmux-fix`, `tmux-kill-session`
- `terminal/iterm2/` – prefs iTerm2 (macOS)

## Uso local (macOS)

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/Documents/terminal-setup
cd ~/Documents/terminal-setup
python3 install.py
source ~/.zshrc
```

Não sobrescreve seu `.zshrc` — só adiciona o bloco `terminal-setup` e os symlinks.

Configure o iTerm2 (aba por host) — ver [iTerm2](#iterm2-macos).

## Uso em servidores

Em **cada** host remoto onde você trabalha:

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/terminal-setup
cd ~/terminal-setup
python3 install.py
source ~/.zshrc
```

Do Mac: `ssh host` → `t`. O tmux roda **no servidor** — builds, logs e sessões persistem se o SSH cair ou o Mac dormir.

Atualizar configs: `git pull` + `python3 install.py` no Mac e nos servidores.

## Uso local (Linux)

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/terminal-setup
cd ~/terminal-setup
python3 install.py
source ~/.zshrc
```

### Instalação completa — Codespaces ou dotfiles completos

Copia `.zshrc`, Oh My Zsh, Cursor CLI, etc.:

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/terminal-setup
cd ~/terminal-setup
python3 install.py --codespaces
exec zsh
```

### iTerm2 (macOS)

1. iTerm2 → Settings → General → Preferences
2. **Load preferences from a custom folder or URL**
3. Aponte para: `<repo>/terminal/iterm2`

**Organização recomendada:** uma tab ou janela iTerm por host (`prod`, `staging`, etc.); tmux fica **dentro** de cada SSH, não no Mac encapsulando conexões remotas.

Recomendação: em Codespaces deixe o GitHub gerenciar clone e cópia; localmente use `python3 install.py` (modo local padrão).
