# terminal-setup — diretrizes para customização e versionamento

Este repositório é a **fonte da verdade** para o ambiente de terminal do Davi. Tudo que deve persistir entre máquinas vive aqui e é aplicado via `install.py`.

Repo: `git@github.com:davirezendemota/terminal-setup.git`

---

## Princípios

1. **Edite no repo, não no `$HOME` solto.** O instalador cria symlinks e blocos gerenciados; mudanças feitas fora do repo se perdem ou não versionam.
2. **Commit + push = disponível em outra máquina.** Depois de customizar, versionar no Git.
3. **Modo local preserva dotfiles locais.** Só o bloco `terminal-setup` é injetado no `~/.zshrc`; **não** sobrescrever `~/.cursor/cli-config.json`, settings do Cursor IDE, `~/.claude/settings.json` nem prefs do iTerm fora de um export intencional para `terminal/iterm2/`.
4. **Mudanças mínimas e focadas.** Preferir evoluir arquivos existentes em vez de duplicar configs ou adicionar dependências pesadas sem necessidade.

---

## Workflow (Mac + servidores)

Camadas separadas — **iTerm2 organiza hosts**, **tmux no host organiza sessões e abas**.

```
Mac (iTerm2)
├── Tab/janela: servidor-a  →  ssh servidor-a  →  tmux (no host)
├── Tab/janela: servidor-b  →  ssh servidor-b  →  tmux (no host)
└── Tab/janela: local (opcional)  →  tmux no Mac, mesma config
```

| Camada | Onde roda | Responsabilidade |
|--------|-----------|------------------|
| **iTerm2** | Mac | Uma tab ou janela por host; título/perfil com nome do servidor |
| **tmux** | Cada host (e Mac local, se quiser) | Sessões persistentes, abas (windows), panes (splits) |
| **terminal-setup** | Mac + todos os hosts | Mesmo `tmux.conf`, nvim, zsh e atalhos em todo lugar |

### Fluxo do dia a dia

1. **Mac:** abrir tab/janela no iTerm2 para o host (ex.: `prod`, `staging`, `dev`).
2. **Conectar:** `ssh meu-host`.
3. **Entrar no tmux:** `t` — attach na última sessão ou cria uma nova se não existir.
4. **Trabalhar:** abas e panes dentro do tmux (ver atalhos abaixo).
5. **Sair sem matar nada:** `Ctrl+d` (detach) — sessão continua no host; feche ou minimize a tab do iTerm.
6. **Voltar depois:** mesma tab ou nova → `ssh` → `t` — retoma onde parou.

### Conceitos tmux neste workflow

| Conceito tmux | Analogia | Atalho principal |
|---------------|----------|------------------|
| **Sessão** | “Ambiente de trabalho” isolado no host | `Ctrl+s` + `S` (nova), `Ctrl+s` + `q` (apagar) |
| **Window (aba)** | Projeto ou contexto dentro da sessão | `Ctrl+s` + `n` (nova), `Ctrl+s` + `x` (fechar) |
| **Pane** | Split na mesma aba | `Ctrl+s` + `h`/`v`, `Ctrl+s` + `w` (fechar) |

**Não usar tmux no Mac para encapsular SSH** — tmux roda **no host remoto** para persistência real (build, logs, agentes sobrevivem a disconnect/rede).

### Instalação por máquina

| Máquina | Comando | iTerm2 |
|---------|---------|--------|
| **Mac** | `python3 install.py` | Apontar prefs para `terminal/iterm2/` |
| **Cada servidor** | `git clone` + `python3 install.py` | — |

Depois de mudanças no repo: `git pull` + `python3 install.py` em **cada** host que usa o setup.

---

## Estrutura e o que cada parte faz

```
terminal-setup/
├── install.py              # instalador principal (local por padrão)
├── install.sh              # wrapper; auto --codespaces no GitHub Codespaces
├── terminal/
│   ├── bin/                # scripts no PATH (tmux-fix, tmux-kill-session)
│   ├── nvim/               # → symlink ~/.config/nvim
│   ├── tmux.conf           # → symlink ~/.tmux.conf
│   ├── zsh/terminal.zsh    # aliases, EDITOR, cores em tmux (sourced pelo ~/.zshrc)
│   └── iterm2/             # com.googlecode.iterm2.plist (prefs versionadas)
├── .zshrc                  # template completo (só copiado com --codespaces)
├── .zprofile
├── .gitconfig
├── .p10k.zsh
├── .cursor/commands/
└── .vscode/                # settings Codespaces — não copiar pro Mac local
```

### Symlinks (modo local e codespaces)

| Destino no sistema | Origem no repo |
|--------------------|----------------|
| `~/.config/nvim` | `terminal/nvim/` |
| `~/.tmux.conf` | `terminal/tmux.conf` |

### Bloco gerenciado no `~/.zshrc` (modo local)

Marcadores — **não editar manualmente fora do instalador**:

```
# >>> terminal-setup BEGIN >>>
# <<< terminal-setup END >>>
```

Variável definida pelo instalador:

```bash
export TERMINAL_SETUP_DIR="<caminho-do-clone>"
```

O arquivo `terminal/zsh/terminal.zsh` é carregado a partir dessa variável.

### O que o instalador faz em cada modo

| Ação | `--codespaces` | local (Mac padrão) |
|------|----------------|---------------------|
| Symlinks nvim/tmux | sim | sim |
| Bloco `terminal-setup` no `~/.zshrc` | copia `.zshrc` completo | injeta só o bloco |
| Copia `.vscode/` → Cursor User | sim | **não** |
| Copia `.cursor/commands/` | sim | sim |
| Oh My Zsh / p10k / Cursor CLI | sim | **não** |
| Meslo Nerd Font (Mac) | — | sim |
| Desativa Ctrl+Space do macOS (input source) | — | sim |
| Desativa keybindings do iTerm | **não** (função existe, não roda sozinha) | **não** |

---

## Onde customizar cada coisa

### Neovim (`terminal/nvim/`)

- **Arquivo principal:** `terminal/nvim/init.lua`
- **Plugins:** Lazy.nvim em `terminal/nvim/lua/plugins/`; lockfile `lazy-lock.json`
- **Navegação tmux/nvim:** `christoomey/vim-tmux-navigator` — `Ctrl+h/j/k/l` (config em `tmux.conf` + plugin nvim)
- **Convenções:** leader `<Space>`, `jj` → Esc, tabs 2 espaços, números relativos
- **Testar:** `nv` ou `nvim` após salvar

### tmux (`terminal/tmux.conf`)

Roda **em cada host** (e no Mac local, se quiser). Sessões persistem no host — essencial para trabalho remoto (ver [Workflow](#workflow-mac--servidores)).

- **Prefix:** `Ctrl+s` (não usar `Ctrl+Space` — conflito com macOS/iTerm)
- **Tema:** [Catppuccin](https://github.com/catppuccin/tmux) `macchiato`, tabs `rounded`, status bar no **topo**
- **Truecolor dentro do tmux:** `terminal-overrides` + `terminal-features` RGB, `update-environment COLORTERM`, `allow-passthrough on` — necessário para **Cursor CLI** e **Claude CLI** colorirem dentro de panes
- **Atalhos (prefix = Ctrl+s, salvo onde indicado):**
  - `r` — reload config
  - `n` — nova aba (cwd atual)
  - `S` — nova sessão (cwd atual)
  - `w` — fechar pane (confirma)
  - `x` — fechar aba (confirma)
  - `h` / `v` — split vertical / horizontal
  - `q` — apagar sessão (confirma; troca p/ outra sessão se existir)
  - `Ctrl+d` — detach (sem prefix)
  - `Ctrl+n` — próxima aba (sem prefix)
  - `Ctrl+h/j/k/l` — vim-tmux-navigator (nvim + panes)
  - `[` → copy mode: `v` seleciona, `y` copia (buffer tmux), `]` cola
- **Recuperar crash:** `tfix` ou `tmux-fix` — limpa socket stale (`server exited unexpectedly`)

### Shell (`terminal/zsh/terminal.zsh`)

- **Aliases:** `t` (attach tmux ou nova sessão), `nv`, `tfix` (tmux-fix)
- **`EDITOR` / `VISUAL`:** nvim local; vim em SSH
- **Dentro do tmux:** `COLORTERM=truecolor`, `FORCE_COLOR=1`, `unset NO_COLOR` — complementa o `tmux.conf` para CLIs Node
- **Não** colocar configs pessoais extensas do Mac aqui — o `.zshrc` local do usuário é separado

### Scripts (`terminal/bin/`)

| Script | Função |
|--------|--------|
| `tmux-fix` | `kill-server` + remove `/tmp/tmux-$UID` + inicia tmux |
| `tmux-kill-session` | mata sessão atual; `switch-client` p/ última outra sessão se houver |

### iTerm2 (`terminal/iterm2/`)

Prefs versionadas em `com.googlecode.iterm2.plist` (export XML do plist live).

**Papel no workflow:** camada de organização no Mac — **uma tab ou janela por host**; tmux roda dentro do SSH em cada servidor (ver [Workflow](#workflow-mac--servidores)).

**Perfil Default salvo (referência):** fonte `MesloLGLNF-Regular 12`, `Terminal Type` = `xterm-256color`, cores light/dark.

**Ativar no iTerm2:**

1. Settings → General → Preferences
2. **Load preferences from a custom folder**
3. Pasta: `<repo>/terminal/iterm2`

**Atualizar plist no repo** (depois de mudar prefs no iTerm):

```bash
plutil -convert xml1 -o ~/Documents/terminal-setup/terminal/iterm2/com.googlecode.iterm2.plist \
  ~/Library/Preferences/com.googlecode.iterm2.plist
```

**Cuidados:**

- **Não** rodar `disable_iterm_keybindings()` no instalador sem pedido explícito — já corrompeu o plist uma vez; usar só `defaults`/`PlistBuddy`, nunca `plistlib.dump` no plist live
- Revisar antes de commitar: paths absolutos (`/Users/davi`), IDs de instalação, prefs de AI do iTerm

### Cursor / Claude CLI (fora deste repo)

Estilização e prefs vivem no `$HOME` — **assistentes não devem alterar** salvo pedido explícito:

| Arquivo | Conteúdo sensível |
|---------|-------------------|
| `~/.cursor/cli-config.json` | `display.*`, permissões, model picker |
| `~/Library/.../Cursor/User/settings.json` | tema Agent, `cursor.composer.*`, extensões |
| `~/.claude/settings.json` | env DeepSeek, `theme`, plugins |

O `.vscode/settings.json` deste repo é **mínimo** e só deve ir pro Cursor User em **`--codespaces`**.

### Dotfiles completos (`.zshrc`, `.gitconfig`, etc.)

- Usados principalmente no **Codespaces**
- No Mac local, `python3 install.py --codespaces` **sobrescreve** o `$HOME` — usar com cuidado

---

## Instalação

```bash
# Mac / servidor — não sobrescreve .zshrc completo nem Cursor User
python3 install.py

# GitHub Codespaces — instalação completa
python3 install.py --codespaces

# Sem instalar neovim/tmux
python3 install.py --skip-deps
```

Após instalar ou puxar mudanças: `source ~/.zshrc` ou abrir terminal novo. Dentro do tmux, abrir **pane novo** para pegar vars de cor.

---

## Pendências conhecidas

- **Cores Cursor CLI no tmux:** dependem de pane novo + `terminal.zsh` + `tmux.conf`; se falhar, testar `echo $COLORTERM $FORCE_COLOR` dentro do pane

---

## Versionamento (Git)

### Fluxo

1. Editar arquivos **dentro do clone**
2. Testar localmente
3. `git add` + `git commit` + `git push`
4. Na outra máquina: `git pull` + `python3 install.py`

### O que **deve** ir pro repo

- Configs de nvim, tmux, zsh, `terminal/bin/`
- `terminal/iterm2/com.googlecode.iterm2.plist` (após revisão)
- Dotfiles do Codespaces, `.cursor/commands/`, `.vscode/` (referência Codespaces)

### O que **não** deve ir pro repo

- Segredos (tokens, senhas, `.env`)
- `.DS_Store`, caches
- Cópias manuais de configs só em `$HOME` sem passar pelo repo

### Mensagens de commit

Preferir commits pequenos e descritivos:

- `feat(nvim): add lazy matchparen highlight`
- `fix(tmux): restore truecolor for cursor cli in panes`
- `chore(iterm2): export Default profile prefs`

---

## Diretrizes para assistentes de IA

Ao modificar este repo:

1. **Neovim:** alterar apenas `terminal/nvim/` (ou subpastas).
2. **tmux:** alterar `terminal/tmux.conf`; manter reload via `~/.tmux.conf`.
3. **Aliases e PATH:** `terminal/zsh/terminal.zsh` ou `terminal/bin/` — não duplicar em `install.py` salvo lógica de instalação.
4. **Não** editar `~/.zshrc` fora do bloco gerenciado / `install.py`.
5. **Não** renomear `TERMINAL_SETUP_DIR` ou marcadores zsh sem atualizar `install.py`.
6. **Modo local é o padrão** — instalador **não** sobrescreve Cursor User, `cli-config.json`, Claude settings nem plist do iTerm automaticamente.
7. **Não** chamar `disable_iterm_keybindings()` no fluxo padrão do `install.py`.
8. **Não** escrever diretamente em `~/Library/Preferences/com.googlecode.iterm2.plist` — exportar para `terminal/iterm2/` se o usuário pedir backup/versionamento.
9. **README.md** e **CLAUDE.md** devem ser atualizados se estrutura ou fluxo mudar de forma relevante.

---

## Máquina nova (checklist)

### Mac

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/Documents/terminal-setup
cd ~/Documents/terminal-setup
python3 install.py
source ~/.zshrc
```

1. iTerm2 → apontar prefs para `terminal/iterm2/` (ou fonte MesloLGS NF manualmente)
2. Uma **tab ou janela iTerm por host** que você acessa com frequência
3. `brew install --cask font-meslo-lg-nerd-font` — o instalador tenta isso no Mac
4. Se tmux local falhar com `server exited unexpectedly`: `tfix`

### Cada servidor

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/terminal-setup
cd ~/terminal-setup
python3 install.py
source ~/.zshrc
```

1. Conectar do Mac: `ssh host`
2. Entrar no tmux: `t`
3. Trabalho persiste no host — `Ctrl+d` para detach, não fechar a sessão com `Ctrl+s` + `q` salvo se for intencional

**Opcional:** reconfigurar Cursor IDE / CLI / Claude CLI no `$HOME` — não vêm deste repo no modo local.
