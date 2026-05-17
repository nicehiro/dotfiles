{ ... }:

{
  xdg.configFile."nvim" = {
    source = ../../.config/nvim;
    force = true;
  };
  xdg.configFile."tmux" = {
    source = ../../.config/tmux;
    force = true;
  };
  xdg.configFile."ghostty" = {
    source = ../../.config/ghostty;
    force = true;
  };
  xdg.configFile."alacritty" = {
    source = ../../.config/alacritty;
    force = true;
  };
  xdg.configFile."starship.toml" = {
    source = ../../.config/starship.toml;
    force = true;
  };
  xdg.configFile."quickshell" = {
    source = ../../.config/quickshell;
    force = true;
  };

  xdg.configFile."fish/config.fish" = {
    source = ../../.config/fish/config.fish;
    force = true;
  };
  xdg.configFile."fish/fish_plugins" = {
    source = ../../.config/fish/fish_plugins;
    force = true;
  };
  xdg.configFile."fish/completions/fisher.fish" = {
    source = ../../.config/fish/completions/fisher.fish;
    force = true;
  };
  xdg.configFile."fish/completions/nvm.fish" = {
    source = ../../.config/fish/completions/nvm.fish;
    force = true;
  };
  xdg.configFile."fish/conf.d/nvm.fish" = {
    source = ../../.config/fish/conf.d/nvm.fish;
    force = true;
  };
  xdg.configFile."fish/functions/fisher.fish" = {
    source = ../../.config/fish/functions/fisher.fish;
    force = true;
  };
  xdg.configFile."fish/functions/nvm.fish" = {
    source = ../../.config/fish/functions/nvm.fish;
    force = true;
  };
  xdg.configFile."fish/functions/_nvm_index_update.fish" = {
    source = ../../.config/fish/functions/_nvm_index_update.fish;
    force = true;
  };
  xdg.configFile."fish/functions/_nvm_list.fish" = {
    source = ../../.config/fish/functions/_nvm_list.fish;
    force = true;
  };
  xdg.configFile."fish/functions/_nvm_version_activate.fish" = {
    source = ../../.config/fish/functions/_nvm_version_activate.fish;
    force = true;
  };
  xdg.configFile."fish/functions/_nvm_version_deactivate.fish" = {
    source = ../../.config/fish/functions/_nvm_version_deactivate.fish;
    force = true;
  };
  xdg.configFile."fish/functions/zj.fish" = {
    source = ../../.config/fish/functions/zj.fish;
    force = true;
  };

  home.file.".gitconfig" = {
    source = ../../.gitconfig;
    force = true;
  };
  home.file.".zshrc" = {
    source = ../../.zshrc;
    force = true;
  };
  home.file.".p10k.zsh" = {
    source = ../../.p10k.zsh;
    force = true;
  };
}
