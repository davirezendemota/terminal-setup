# terminal-setup — diretrizes para customização e versionamento

Este repositório é a **fonte da verdade** para o ambiente de terminal do Davi. Tudo que deve persistir entre máquinas vive aqui e é aplicado via `install.py`.

Repo: `git@github.com:davirezendemota/terminal-setup.git`

---

## Princípios

1. **Edite no repo, não no `$HOME` solto.** O instalador cria symlinks e blocos gerenciados; mudanças feitas fora do repo se perdem ou não versionam.
2. **Commit + push = disponível em outra máquina.** Depois de customizar, versionar no Git.
3. **Modo local preserva `.zshrc` existente.** Só o bloco `terminal-setup` é injetado; o resto do shell local do usuário não deve ser sobrescrito sem pedido explícito.
4. **Mudanças mínimas e focadas.** Preferir evoluir arquivos existentes em vez de duplicar configs ou adicionar dependências pesadas sem necessidade.

---

## Estrutura e o que cada parte faz

```
terminal-setup/
├── install.py              # instalador principal (local por padrão)
├── install.sh              # wrapper; auto --codespaces no GitHub Codespaces
├── terminal/
│   ├── nvim/               # → symlink ~/.config/nvim
│   ├── tmux.conf           # → symlink ~/.tmux.conf
│   ├── zsh/terminal.zsh    # aliases t/nv, EDITOR (sourced pelo ~/.zshrc)
│   └── iterm2/             # prefs iTerm2 (macOS; ativação manual)
├── .zshrc                  # template completo (só copiado com --codespaces)
├── .zprofile
├── .gitconfig
├── .p10k.zsh
├── .cursor/commands/
└── .vscode/
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

### Copiado para `$HOME` (somente `--codespaces`)

`.zshrc`, `.zprofile`, `.gitconfig`, `.p10k.zsh`, `.cursor/commands/`, settings do Cursor/VS Code.

---

## Onde customizar cada coisa

### Neovim (`terminal/nvim/`)

- **Arquivo principal:** `terminal/nvim/init.lua`
- **Interface, keymaps, opções:** editar aqui ou adicionar módulos em `terminal/nvim/lua/`, `terminal/nvim/after/`, etc.
- **Plugins:** se adicionar gerenciador (Lazy.nvim, etc.), manter lockfile e config **dentro de `terminal/nvim/`** — nunca em `~/.local/share/nvim` versionado à parte.
- **Convenções atuais:** leader `<Space>`, `jj` → Esc, tabs 2 espaços, números relativos.
- **Testar:** `nv` ou `nvim` após salvar.

### tmux (`terminal/tmux.conf`)

- Prefix: `Ctrl-a`
- Reload: `prefix + r` (recarrega `~/.tmux.conf`, que aponta para este arquivo)
- Splits: `|` horizontal, `-` vertical

### Shell local (`terminal/zsh/terminal.zsh`)

- Aliases de terminal: `t`, `nv`
- `EDITOR` / `VISUAL`
- **Não** colocar aqui configs pessoais extensas do Mac — o `.zshrc` local do usuário é separado.

### iTerm2 (`terminal/iterm2/`)

- Opcional; requer apontar o iTerm2 para essa pasta nas prefs.
- O plist pode conter preferências específicas da máquina — commitar só o que for intencionalmente portável.

### Dotfiles completos (`.zshrc`, `.gitconfig`, etc.)

- Usados principalmente no **Codespaces**.
- Alterações afetam ambientes novos criados lá; no Mac local, `--codespaces` **sobrescreve** o `$HOME` — usar com cuidado.

---

## Instalação

```bash
# Mac / servidor — não sobrescreve .zshrc completo
python3 install.py

# GitHub Codespaces — instalação completa
python3 install.py --codespaces

# Sem instalar neovim/tmux
python3 install.py --skip-deps
```

Após instalar ou puxar mudanças: `source ~/.zshrc` ou abrir terminal novo.

---

## Versionamento (Git)

### Fluxo

1. Editar arquivos **dentro do clone** (`~/Documents/terminal-setup` ou equivalente)
2. Testar localmente
3. `git add` + `git commit` + `git push`
4. Na outra máquina: `git pull` + `python3 install.py` (reaplica symlinks e bloco zsh)

### O que **deve** ir pro repo

- Configs de nvim, tmux, zsh do terminal
- Mudanças intencionais em dotfiles do Codespaces
- Comandos Cursor (`.cursor/commands/`)
- Settings/keybindings compartilhados (`.vscode/`)

### O que **não** deve ir pro repo

- Segredos (tokens, senhas, `.env`)
- `.DS_Store`, caches, lockfiles de ferramentas externas não relacionadas
- Plist/state de iTerm2 com dados sensíveis ou específicos de uma máquina, salvo se revisado
- Cópias manuais de configs feitas só em `~` sem passar pelo repo

### Mensagens de commit

Preferir commits pequenos e descritivos:

- `feat(nvim): add lazy matchparen highlight`
- `fix(tmux): restore prefix reload on linux`
- `chore(install): handle missing brew on mac`

---

## Diretrizes para assistentes de IA

Ao modificar este repo:

1. **Neovim:** alterar apenas `terminal/nvim/` (ou subpastas dentro dela).
2. **tmux:** alterar `terminal/tmux.conf`; manter reload via `~/.tmux.conf`.
3. **Aliases de terminal:** `terminal/zsh/terminal.zsh` — não duplicar em `install.py` salvo se for lógica de instalação.
4. **Não** editar o `~/.zshrc` do usuário diretamente; usar o bloco gerenciado ou `install.py`.
5. **Não** renomear `TERMINAL_SETUP_DIR` ou os marcadores zsh sem atualizar `install.py`.
6. **Não** adicionar dependências ao instalador além da stdlib Python, salvo pedido explícito.
7. **Modo local é o padrão** — mudanças no instalador não devem passar a sobrescrever dotfiles locais por default.
8. **README.md** e **CLAUDE.md** devem ser atualizados se a estrutura ou o fluxo mudar de forma relevante.

---

## Máquina nova (checklist)

```bash
git clone git@github.com:davirezendemota/terminal-setup.git ~/Documents/terminal-setup
cd ~/Documents/terminal-setup
python3 install.py
source ~/.zshrc
```

Opcional iTerm2: apontar prefs para `terminal/iterm2/`.
