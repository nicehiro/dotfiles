# dotfiles

Personal dotfiles for macOS and Linux, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```
.config/          App configs (nvim, ghostty, tmux, alacritty, starship, etc.)
.claude/          Claude Code settings, commands, and skills
.pi/              Pi coding agent config (extensions, themes, skills)
nix/darwin/       nix-darwin flake for declarative macOS setup
bin/              Utility scripts
.zshrc            Zsh config (zinit, fzf, starship)
.gitconfig        Git user config
.config/starship.toml   Starship prompt config
```

## Setup

### Linux

```bash
git clone https://github.com/fangyuan/dotfiles ~/dotfiles
cd ~/dotfiles
stow .
```

### macOS

```bash
# 1. Clone
git clone https://github.com/fangyuan/dotfiles ~/dotfiles

# 2. Apply nix-darwin (installs packages, sets macOS defaults)
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin#mbp

# 3. Stow configs into ~
cd ~/dotfiles
stow .
```

## Notes

- Shell configs try common Homebrew/Linuxbrew locations automatically.
- Shell environment paths use `$HOME` instead of hardcoded `/Users/...` paths.
- Fish plugin declarations live in `.config/fish/fish_plugins`, and the current plugin functions are committed for a working out-of-the-box setup.
- `nix/darwin/` remains macOS-specific by design.
- Some GUI configs are naturally platform-specific, but core shell/editor/terminal configs are intended to work on both macOS and Linux.

## Key Tools

| Tool | Purpose |
|------|---------|
| **Neovim** | Primary editor |
| **Ghostty** | Terminal emulator |
| **Tmux** | Terminal multiplexer |
| **Starship** | Shell prompt |
| **Zsh + zinit** | Shell with plugin manager |
| **fzf** | Fuzzy finder |
| **Pi** | AI coding agent |
| **Claude Code** | AI coding agent |
