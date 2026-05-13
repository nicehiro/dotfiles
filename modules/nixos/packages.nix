{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    fd
    fish
    fzf
    gcc
    git
    gnome-tweaks
    ghostty
    neovim
    nodejs
    ripgrep
    sing-box
    starship
    stow
    tailscale
  ];
}
