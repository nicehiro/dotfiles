# nix/darwin

Declarative macOS system configuration using [nix-darwin](https://github.com/LnL7/nix-darwin) and [nix-homebrew](https://github.com/zhaofengli/nix-homebrew).

## Usage

```bash
# Apply configuration
sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin#mbp

# Update flake inputs
cd ~/dotfiles/nix/darwin && nix flake update
```

## What it manages

**Nix packages** — stow, neovim, tmux, fzf, go, git, uv, hugo, starship, ripgrep, claude-code, etc.

**Homebrew formulae** — node, gh, ffmpeg, rustup, sing-box, librime, poppler, gcc, etc.

**Homebrew casks** — Ghostty, Zed, Emacs, Chrome, Figma, Spotify, Zotero, Steam, fonts, etc.

**Mac App Store** — Shadowrocket, Infuse

**macOS defaults** — dock autohide, finder settings, trackpad, hot corners, 24-hour clock, key repeat, etc.
