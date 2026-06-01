{ ... }:

{
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.neovim = {
    enable = true;
    withPython3 = true;
    withRuby = true;
  };
}
