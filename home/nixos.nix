{ ... }:

{
  imports = [
    ../modules/home/common.nix
    ../modules/home/dotfiles.nix
    ../modules/home/emacs.nix
    ../modules/home/hyprland.nix
    ../modules/home/latex.nix
    ../modules/home/quickshell.nix
  ];

  home.username = "fangyuan";
  home.homeDirectory = "/home/fangyuan";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
