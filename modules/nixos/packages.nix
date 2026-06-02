{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    fish
    gcc
    git
    gh
    gnome-tweaks
    zed-editor
    ghostty
    nodejs
    sing-box
    stow
    tailscale
  ];
}
