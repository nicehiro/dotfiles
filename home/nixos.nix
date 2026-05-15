{ ... }:

{
  imports = [
    ../modules/home/common.nix
    ../modules/home/dotfiles.nix
    ../modules/home/hyprland.nix
  ];

  home.username = "fangyuan";
  home.homeDirectory = "/home/fangyuan";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
