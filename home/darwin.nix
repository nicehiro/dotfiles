{ ... }:

{
  imports = [
    ../modules/home/common.nix
  ];

  home.username = "fangyuan";
  home.homeDirectory = "/Users/fangyuan";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
