{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    pamixer
    playerctl
    pavucontrol

    wl-clipboard
    grim
    slurp
    hyprshot
    hyprpicker
    wofi

    mako
    hyprpaper
    hyprlock
    hypridle

    networkmanagerapplet
    blueman
  ];
}
