{ pkgs, ... }:

let
  cursorTheme = "Bibata-Modern-Ice";
  cursorSize = 32;
in
{
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = cursorTheme;
    size = cursorSize;
  };

  gtk = {
    enable = true;
    cursorTheme = {
      package = pkgs.bibata-cursors;
      name = cursorTheme;
      size = cursorSize;
    };
  };
}
