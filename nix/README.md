# Nix configs

Declarative system configuration for NixOS, Ubuntu Home Manager, and macOS via nix-darwin.

## macOS

```bash
# Build without activating
darwin-rebuild build --flake ~/dotfiles#mbp

# Apply configuration
sudo darwin-rebuild switch --flake ~/dotfiles#mbp
```

## NixOS

```bash
sudo nixos-rebuild switch --flake ~/dotfiles#nixos
```

## Ubuntu / standalone Home Manager

```bash
home-manager switch --flake ~/dotfiles#fangyuan-ubuntu
```

## Update flake inputs

```bash
cd ~/dotfiles && nix flake update
```
