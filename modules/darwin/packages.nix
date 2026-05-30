{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    stow
    go
    git
    mkalias
    neovim
    tmux
    fzf
    hugo
    coreutils
    yarn
    aria2
    hledger
    uv
    wget
    ghostscript
    pdf2svg
    cmake
    glibtool
    imagemagick
    starship
    android-tools
    claude-code
    opencode
    ripgrep
    fish
  ];
}
