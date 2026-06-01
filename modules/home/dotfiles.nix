{ pkgs, ... }:

{
  xdg.configFile."nvim" = {
    source = ../../.config/nvim;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."tmux" = {
    source = ../../.config/tmux;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."ghostty" = {
    source = ../../.config/ghostty;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."alacritty" = {
    source = ../../.config/alacritty;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."starship.toml" = {
    source = ../../.config/starship.toml;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."quickshell" = {
    source = ../../.config/quickshell;
    force = pkgs.stdenv.isLinux;
  };

  xdg.configFile."fish/config.fish" = {
    source = ../../.config/fish/config.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/fish_plugins" = {
    source = ../../.config/fish/fish_plugins;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/completions/fisher.fish" = {
    source = ../../.config/fish/completions/fisher.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/completions/nvm.fish" = {
    source = ../../.config/fish/completions/nvm.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/conf.d/nvm.fish" = {
    source = ../../.config/fish/conf.d/nvm.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/functions/fisher.fish" = {
    source = ../../.config/fish/functions/fisher.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/functions/nvm.fish" = {
    source = ../../.config/fish/functions/nvm.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/functions/_nvm_index_update.fish" = {
    source = ../../.config/fish/functions/_nvm_index_update.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/functions/_nvm_list.fish" = {
    source = ../../.config/fish/functions/_nvm_list.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/functions/_nvm_version_activate.fish" = {
    source = ../../.config/fish/functions/_nvm_version_activate.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/functions/_nvm_version_deactivate.fish" = {
    source = ../../.config/fish/functions/_nvm_version_deactivate.fish;
    force = pkgs.stdenv.isLinux;
  };
  xdg.configFile."fish/functions/zj.fish" = {
    source = ../../.config/fish/functions/zj.fish;
    force = pkgs.stdenv.isLinux;
  };

  home.file.".gitconfig" = {
    source = ../../.gitconfig;
    force = pkgs.stdenv.isLinux;
  };
  home.file.".zshrc" = {
    source = ../../.zshrc;
    force = pkgs.stdenv.isLinux;
  };
  home.file.".p10k.zsh" = {
    source = ../../.p10k.zsh;
    force = pkgs.stdenv.isLinux;
  };
}
