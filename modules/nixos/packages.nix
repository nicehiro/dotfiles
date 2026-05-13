{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    fish
    gcc
    git
		gh
    gnome-tweaks
    ghostty
    nodejs
    sing-box
    stow
    tailscale
  ];
}
