{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/nix.nix
    ../../modules/nixos/desktop-gnome.nix
    ../../modules/nixos/desktop-hyprland.nix
    ../../modules/nixos/users.nix
    ../../modules/nixos/packages.nix
    ../../modules/nixos/services.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Hong_Kong";
  i18n.defaultLocale = "en_HK.UTF-8";

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.fish.enable = true;
  users.users.fangyuan.shell = pkgs.fish;

  system.stateVersion = "25.11";
}
