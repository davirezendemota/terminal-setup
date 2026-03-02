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

## Uso local (opcional)

Para aplicar no seu macOS/Linux sem Codespaces:

```bash
git clone <este-repo> ~/dotfiles
cd ~/dotfiles
# Copiar arquivos manualmente ou rodar install e symlink
./install.sh
# Os dotfiles já em $HOME podem ter sido sobrescritos pelo clone; ajuste conforme necessário.
```

Recomendação: em Codespaces deixe o GitHub gerenciar clone e cópia; localmente use o repositório como referência e copie/ajuste apenas o que quiser.
