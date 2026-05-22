{ pkgs, ... }:

{
  home.packages = with pkgs; [
    cliphist
    libnotify

    wofi
    mako
    hyprpaper
    hyprlock
    hypridle
  ];
}
