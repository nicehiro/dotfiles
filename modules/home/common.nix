{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    curl
    eza
    fd
    fzf
    htop
    jq
    ripgrep
    starship
    tree
    unzip
    uv
    wget
    zoxide
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.neovim = {
    enable = true;
    withPython3 = true;
    withRuby = true;
  };
}
