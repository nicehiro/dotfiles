{ ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
    };

    taps = [
      "d12frosted/emacs-plus"
      "tw93/tap"
      "owo-network/brew"
    ];

    brews = [
      "mas"
      "aspell"
      "xcodes"
      "node"
      "ttfautohint"
      "pngpaste"
      "lua-language-server"
      "gh"
      "ffmpeg"
      "mole"
      "ty"
      "cocoapods"
      "librime"
      "poppler"
      "jpeg"
      "gcc"
      "gdk-pixbuf"
      "isl"
      "libgccjit"
      "libmpc"
      "librsvg"
      "mpfr"
      "tree-sitter"
      "zlib"
      "rustup"
    ];

    casks = [
      "sfm"
      "emacs-plus-app@master"
      "thebrowsercompany-dia"
      "google-chrome"
      "tailscale-app"
      "orbstack"
      "visual-studio-code"
      "zed"
      "ghostty"
      "wezterm"
      "windows-app"
      "wakatime"
      "kitlangton-hex"
      "chatgpt"
      "codex-app"
      "claude"
      "linearmouse"
      "inkscape"
      "figma"
      "zoom"
      "netnewswire"
      "steam"
      "telegram"
      "mactex"
      "squirrel-app"
      "iina"
      "keka"
      "zotero"
      "google-drive"
      "appcleaner"
      "tencent-meeting"
      "microsoft-office"
      "alt-tab"
      "calibre"
      "lyric-fever"
      "spotify"
      "font-lxgw-wenkai"
      "font-jetbrains-mono-nerd-font"
      "font-maple-mono-nf"
      "font-maple-mono-nf-cn"
      "font-zed-mono-nerd-font"
      "font-zed-sans"
      "font-literata"
      "font-geist-mono-nerd-font"
      "font-ioskeley-mono"
    ];
  };
}
