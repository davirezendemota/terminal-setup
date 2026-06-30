#!/usr/bin/env python3
"""terminal-setup installer — local mode by default, full stack with --codespaces."""

from __future__ import annotations

import argparse
import getpass
import os
import platform
import re
import shutil
import subprocess
import sys
from pathlib import Path

TERMINAL_MARKER_BEGIN = "# >>> terminal-setup BEGIN >>>"
TERMINAL_MARKER_END = "# <<< terminal-setup END >>>"

LEGACY_ZSHRC_PATTERNS = [
    r"Documents/terminal-config/zsh/terminal\.zsh",
    r"Documents/dotfiles/terminal/zsh/terminal\.zsh",
    r"^# Terminal configs \(tmux, neovim, editor\)$",
    r"^# >>> terminal-config BEGIN >>>$",
    r"^# <<< terminal-config END >>>$",
    r"^# >>> dotfiles terminal BEGIN >>>$",
    r"^# <<< dotfiles terminal END >>>$",
    r"^export TERMINAL_CONFIG_DIR=",
    r"^export DOTFILES_DIR=",
    r"TERMINAL_CONFIG_DIR/terminal/zsh/terminal\.zsh",
    r"DOTFILES_DIR/terminal/zsh/terminal\.zsh",
    r"^# Path to dotfiles repo",
]

TERMINAL_TITLE_ZSH = """\
# Terminal title (terminal-setup)
_set_terminal_title() {
  local title="${HAWKOS_TERMINAL_TITLE:-HawkOS — pronto}"
  printf '\\033]0;%s\\007' "$title"
}
if type add-zsh-hook &>/dev/null; then
  add-zsh-hook precmd _set_terminal_title
else
  precmd_functions+=(_set_terminal_title)
fi
"""

TERMINAL_TITLE_BASH = """\
# Terminal title (terminal-setup)
_set_terminal_title() {
  local title="${HAWKOS_TERMINAL_TITLE:-HawkOS — pronto}"
  printf '\\033]0;%s\\007' "$title"
}
PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}_set_terminal_title"
"""


class Installer:
    def __init__(self, repo_dir: Path, *, codespaces: bool, install_deps: bool) -> None:
        self.repo_dir = repo_dir.resolve()
        self.codespaces = codespaces
        self.install_deps = install_deps
        self.home = Path.home()
        self.zshrc = Path(os.environ.get("ZSHRC", self.home / ".zshrc"))

    def log(self, message: str) -> None:
        print(f"==> {message}")

    def run(
        self,
        cmd: list[str],
        *,
        check: bool = True,
        capture: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        if capture:
            return subprocess.run(cmd, check=check, text=True, capture_output=True)
        return subprocess.run(cmd, check=check, text=True)

    def command_exists(self, name: str) -> bool:
        return shutil.which(name) is not None

    def install(self) -> None:
        mode = "codespaces" if self.codespaces else "local"
        self.log(f"terminal-setup install ({mode}) from {self.repo_dir}")

        if self.install_deps:
            self.install_terminal_deps()

        self.install_terminal_configs()

        if self.codespaces:
            self.copy_shell_dotfiles()
            self.install_terminal_title()
            self.install_cursor_commands()
            self.install_vscode_cursor_user()
            self.install_shell_stack()
        else:
            self.ensure_terminal_setup_in_zshrc()
            self.install_cursor_commands()
            self.install_vscode_cursor_user()

        if self.codespaces:
            self.log("terminal-setup install done. Open a new terminal or run: exec zsh")
        else:
            self.log("Local install done. Run: source ~/.zshrc")

    def install_terminal_deps(self) -> None:
        if self.command_exists("nvim") and self.command_exists("tmux"):
            self.log("neovim and tmux already installed")
            return

        system = platform.system()
        if system == "Darwin":
            if not self.command_exists("brew"):
                self.log("Homebrew not found; install neovim/tmux manually")
                return
            self.log("Installing neovim and tmux (Homebrew)...")
            self.run(["brew", "install", "neovim", "tmux"])
            return

        if system == "Linux":
            if self.command_exists("apt-get"):
                self.log("Installing neovim and tmux (apt)...")
                self.run(["sudo", "apt-get", "update", "-qq"])
                self.run(["sudo", "apt-get", "install", "-y", "neovim", "tmux"])
            elif self.command_exists("dnf"):
                self.log("Installing neovim and tmux (dnf)...")
                self.run(["sudo", "dnf", "install", "-y", "neovim", "tmux"])
            elif self.command_exists("pacman"):
                self.log("Installing neovim and tmux (pacman)...")
                self.run(["sudo", "pacman", "-S", "--needed", "neovim", "tmux"])
            else:
                self.log("Could not detect package manager; install neovim and tmux manually")
            return

        self.log(f"Unsupported OS for dependency install: {system}")

    def install_terminal_configs(self) -> None:
        term_dir = self.repo_dir / "terminal"
        if not term_dir.is_dir():
            self.log("No terminal/ directory found; skipping nvim/tmux setup")
            return

        self.log("Installing terminal configs (nvim, tmux)")
        config_dir = self.home / ".config"
        config_dir.mkdir(parents=True, exist_ok=True)

        nvim_link = config_dir / "nvim"
        tmux_link = self.home / ".tmux.conf"
        self._symlink(term_dir / "nvim", nvim_link)
        self._symlink(term_dir / "tmux.conf", tmux_link)
        self.log(f"Linked {nvim_link} -> {term_dir / 'nvim'}")
        self.log(f"Linked {tmux_link} -> {term_dir / 'tmux.conf'}")

    def _symlink(self, target: Path, link: Path) -> None:
        if link.is_symlink() or link.exists():
            link.unlink()
        link.symlink_to(target)

    def ensure_terminal_setup_in_zshrc(self) -> None:
        self.zshrc.touch(exist_ok=True)
        content = self._read_text(self.zshrc)
        content = self._remove_terminal_block(content)
        content = self._remove_legacy_lines(content)
        content = self._set_terminal_setup_dir(content)
        content = self._append_terminal_block(content)
        self._write_text(self.zshrc, content)
        self.log(f"Updated {self.zshrc} with TERMINAL_SETUP_DIR and terminal integration")

    def _read_text(self, path: Path) -> str:
        return path.read_text(encoding="utf-8")

    def _write_text(self, path: Path, content: str) -> None:
        path.write_text(content.rstrip() + "\n", encoding="utf-8")

    def _remove_terminal_block(self, content: str) -> str:
        lines = content.splitlines()
        result: list[str] = []
        skip = False
        for line in lines:
            if line == TERMINAL_MARKER_BEGIN:
                skip = True
                continue
            if line == TERMINAL_MARKER_END:
                skip = False
                continue
            if not skip:
                result.append(line)
        return "\n".join(result)

    def _remove_legacy_lines(self, content: str) -> str:
        lines = content.splitlines()
        result: list[str] = []
        for line in lines:
            if any(re.search(pattern, line) for pattern in LEGACY_ZSHRC_PATTERNS):
                continue
            result.append(line)
        return "\n".join(result)

    def _set_terminal_setup_dir(self, content: str) -> str:
        export_line = f'export TERMINAL_SETUP_DIR="{self.repo_dir}"'
        if re.search(r"^export TERMINAL_SETUP_DIR=", content, flags=re.MULTILINE):
            return re.sub(
                r"^export TERMINAL_SETUP_DIR=.*$",
                export_line,
                content,
                count=1,
                flags=re.MULTILINE,
            )

        block = (
            f"\n# Path to terminal-setup repo (set by install.py)\n"
            f"{export_line}\n"
        )
        return content + block

    def _append_terminal_block(self, content: str) -> str:
        if TERMINAL_MARKER_BEGIN in content:
            return content

        block = f"""
{TERMINAL_MARKER_BEGIN}
[[ -f "$TERMINAL_SETUP_DIR/terminal/zsh/terminal.zsh" ]] && source "$TERMINAL_SETUP_DIR/terminal/zsh/terminal.zsh"
{TERMINAL_MARKER_END}
"""
        return content + block

    def copy_shell_dotfiles(self) -> None:
        for name in (".zshrc", ".zprofile", ".gitconfig", ".p10k.zsh"):
            source = self.repo_dir / name
            if source.is_file():
                self.log(f"Copying {name} to $HOME")
                shutil.copy2(source, self.home / name)

        zshrc_path = self.home / ".zshrc"
        if zshrc_path.is_file():
            content = self._read_text(zshrc_path)
            content = re.sub(
                r'^export TERMINAL_SETUP_DIR=.*$',
                f'export TERMINAL_SETUP_DIR="{self.repo_dir}"',
                content,
                count=1,
                flags=re.MULTILINE,
            )
            self._write_text(zshrc_path, content)

    def install_terminal_title(self) -> None:
        if self.zshrc.is_file() and "_set_terminal_title" not in self._read_text(self.zshrc):
            self.log("Adding terminal title to .zshrc")
            with self.zshrc.open("a", encoding="utf-8") as handle:
                handle.write("\n" + TERMINAL_TITLE_ZSH)

        bashrc = self.home / ".bashrc"
        bashrc.touch(exist_ok=True)
        if "_set_terminal_title" not in self._read_text(bashrc):
            self.log("Adding terminal title to .bashrc")
            with bashrc.open("a", encoding="utf-8") as handle:
                handle.write("\n" + TERMINAL_TITLE_BASH)

    def install_cursor_commands(self) -> None:
        source = self.repo_dir / ".cursor" / "commands"
        if not source.is_dir():
            return

        target = self.home / ".cursor" / "commands"
        target.mkdir(parents=True, exist_ok=True)
        self.log("Copying .cursor/commands to $HOME/.cursor")
        for item in source.iterdir():
            dest = target / item.name
            if item.is_dir():
                if dest.exists():
                    shutil.rmtree(dest)
                shutil.copytree(item, dest)
            else:
                shutil.copy2(item, dest)

    def install_vscode_cursor_user(self) -> None:
        vscode_dir = self.repo_dir / ".vscode"
        if not vscode_dir.is_dir():
            return

        if platform.system() == "Darwin":
            cursor_user = self.home / "Library" / "Application Support" / "Cursor" / "User"
        else:
            cursor_user = Path(os.environ.get("XDG_CONFIG_HOME", self.home / ".config")) / "Cursor" / "User"

        cursor_user.mkdir(parents=True, exist_ok=True)
        for name in ("settings.json", "keybindings.json"):
            source = vscode_dir / name
            if source.is_file():
                self.log(f"Copying .vscode/{name} to Cursor User")
                shutil.copy2(source, cursor_user / name)

    def install_shell_stack(self) -> None:
        if not self.command_exists("zsh") and self.command_exists("apt-get"):
            self.log("Installing zsh...")
            self.run(["sudo", "apt-get", "update", "-qq"])
            self.run(["sudo", "apt-get", "install", "-y", "zsh"])

        if not self.command_exists("cursor"):
            self.log("Installing Cursor Agent CLI...")
            self.run(["bash", "-lc", "curl -fsSL https://cursor.com/install | bash"], check=False)
        else:
            self.log("Cursor CLI already installed.")

        if self.command_exists("zsh"):
            shell = os.environ.get("SHELL", "")
            if shell and Path(shell).name != "zsh":
                self.log("Setting default shell to zsh...")
                self.run(["sudo", "chsh", "-s", shutil.which("zsh") or "zsh", getpass.getuser()], check=False)

        if not self.command_exists("python3") and self.command_exists("apt-get"):
            self.log("Installing Python3...")
            self.run(["sudo", "apt-get", "update", "-qq"])
            self.run(["sudo", "apt-get", "install", "-y", "python3", "python3-pip"])

        if not self.command_exists("pipenv") and self.command_exists("pip3"):
            self.log("Installing pipenv...")
            self.run(["pip3", "install", "--user", "pipenv"], check=False)

        if not self.command_exists("node"):
            self.log("Installing Node.js via nvm...")
            nvm_dir = self.home / ".nvm"
            if not (nvm_dir / "nvm.sh").is_file():
                self.run(
                    ["bash", "-lc", "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"],
                    check=False,
                )
            self.run(["bash", "-lc", "source ~/.nvm/nvm.sh && nvm install --lts"], check=False)

        if not (self.home / ".oh-my-zsh").is_dir():
            self.log("Installing Oh My Zsh...")
            self.run(
                [
                    "bash",
                    "-lc",
                    'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended',
                ],
                check=False,
            )

        zsh_custom = Path(os.environ.get("ZSH_CUSTOM", self.home / ".oh-my-zsh" / "custom"))
        for plugin in ("zsh-autosuggestions", "zsh-syntax-highlighting"):
            target = zsh_custom / "plugins" / plugin
            if not target.is_dir():
                self.log(f"Installing zsh plugin: {plugin}")
                self.run(
                    ["git", "clone", "--depth=1", f"https://github.com/zsh-users/{plugin}.git", str(target)],
                    check=False,
                )

        p10k = zsh_custom / "themes" / "powerlevel10k"
        if not p10k.is_dir():
            self.log("Installing Powerlevel10k theme...")
            self.run(
                ["git", "clone", "--depth=1", "https://github.com/romkatv/powerlevel10k.git", str(p10k)],
                check=False,
            )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Install terminal-setup configs.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 install.py                  # local machine (default)
  python3 install.py --codespaces     # full install for GitHub Codespaces
  python3 install.py --skip-deps      # local without installing neovim/tmux
        """.strip(),
    )
    parser.add_argument(
        "--codespaces",
        action="store_true",
        help="Full install: copy shell dotfiles, Oh My Zsh, Cursor CLI, etc.",
    )
    parser.add_argument(
        "--skip-deps",
        action="store_true",
        help="Do not install neovim and tmux",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    repo_dir = Path(__file__).resolve().parent
    installer = Installer(
        repo_dir,
        codespaces=args.codespaces,
        install_deps=not args.skip_deps,
    )
    try:
        installer.install()
    except subprocess.CalledProcessError as exc:
        print(f"install failed: {exc}", file=sys.stderr)
        return exc.returncode or 1
    except OSError as exc:
        print(f"install failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
