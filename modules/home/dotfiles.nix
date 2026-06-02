{ config, pkgs, ... }:

let
  linuxForce = pkgs.stdenv.isLinux;
  dotfilesDir = "${config.home.homeDirectory}/dotfiles";
in
{
  xdg.configFile."nvim" = {
    source = ../../.config/nvim;
    force = linuxForce;
  };
  xdg.configFile."tmux" = {
    source = ../../.config/tmux;
    force = linuxForce;
  };
  xdg.configFile."ghostty" = {
    source = ../../.config/ghostty;
    force = linuxForce;
  };
  xdg.configFile."alacritty" = {
    source = ../../.config/alacritty;
    force = linuxForce;
  };
  xdg.configFile."starship.toml" = {
    source = ../../.config/starship.toml;
    force = linuxForce;
  };
  xdg.configFile."quickshell" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/quickshell";
    force = linuxForce;
  };
  xdg.configFile."hypr" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/hypr";
    force = linuxForce;
  };
  xdg.configFile."wofi" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/wofi";
    force = linuxForce;
  };
  xdg.configFile."mako" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/mako";
    force = linuxForce;
  };

  xdg.configFile."fish/config.fish" = {
    source = ../../.config/fish/config.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/fish_plugins" = {
    source = ../../.config/fish/fish_plugins;
    force = linuxForce;
  };
  xdg.configFile."fish/completions/fisher.fish" = {
    source = ../../.config/fish/completions/fisher.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/completions/nvm.fish" = {
    source = ../../.config/fish/completions/nvm.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/conf.d/nvm.fish" = {
    source = ../../.config/fish/conf.d/nvm.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/functions/fisher.fish" = {
    source = ../../.config/fish/functions/fisher.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/functions/nvm.fish" = {
    source = ../../.config/fish/functions/nvm.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/functions/_nvm_index_update.fish" = {
    source = ../../.config/fish/functions/_nvm_index_update.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/functions/_nvm_list.fish" = {
    source = ../../.config/fish/functions/_nvm_list.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/functions/_nvm_version_activate.fish" = {
    source = ../../.config/fish/functions/_nvm_version_activate.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/functions/_nvm_version_deactivate.fish" = {
    source = ../../.config/fish/functions/_nvm_version_deactivate.fish;
    force = linuxForce;
  };
  xdg.configFile."fish/functions/zj.fish" = {
    source = ../../.config/fish/functions/zj.fish;
    force = linuxForce;
  };

  home.file.".local/bin/hypr-theme" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/bin/hypr-theme";
    force = linuxForce;
  };

  home.file.".gitconfig" = {
    source = ../../.gitconfig;
    force = linuxForce;
  };
  home.file.".zshrc" = {
    source = ../../.zshrc;
    force = linuxForce;
  };
  home.file.".p10k.zsh" = {
    source = ../../.p10k.zsh;
    force = linuxForce;
  };
}
