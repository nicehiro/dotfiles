{ pkgs, ... }:

{
  programs.zsh.enable = false;
  programs.fish.enable = true;

  environment.shells = [ pkgs.fish ];
}
