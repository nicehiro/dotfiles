# dotfiles

Personal dotfiles for macOS (Apple Silicon), managed with [GNU Stow](https://www.gnu.org/software/stow/) and [nix-darwin](https://github.com/LnL7/nix-darwin).

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

```bash
# 1. Clone
git clone https://github.com/fangyuan/dotfiles ~/dotfiles

# 2. Apply nix-darwin (installs packages, sets macOS defaults)
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin#mbp

# 3. Stow configs into ~
cd ~/dotfiles
stow .
```

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
