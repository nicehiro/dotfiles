# Usage:
# sudo darwin-rebuild switch --flake ~/dotfiles/nix/darwin#mbp
# nix flake update
{
  description = "FY's flakes of nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-emacsplus = {
      url = "github:d12frosted/homebrew-emacs-plus";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-tw93 = {
      url = "github:tw93/homebrew-tap";
      flake = false;
    };
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-emacsplus, homebrew-core, homebrew-cask, homebrew-tw93, claude-code }:
  let
    configuration = { pkgs, config, ... }: {

      nix.enable = false;
      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowBroken = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.stow
          pkgs.go
          pkgs.git
          pkgs.mkalias
          pkgs.neovim
          pkgs.tmux
          pkgs.fzf
          pkgs.hugo
          pkgs.coreutils
          pkgs.dict
          pkgs.cloudflared
          pkgs.yarn
          pkgs.aria2
          pkgs.hledger
          pkgs.uv
          pkgs.wget
          pkgs.ghostscript
          pkgs.pdf2svg
          pkgs.cmake
          pkgs.glibtool
          pkgs.julia-mono
          pkgs.imagemagick
          pkgs.starship
          pkgs.android-tools
          pkgs.claude-code
          pkgs.opencode
          pkgs.ripgrep
        ];

      homebrew = {
        enable = true;
        onActivation = {
          autoUpdate = true;   # runs `brew update`
          upgrade    = true;   # upgrades outdated formulae
          cleanup    = "zap";  # optional: removes old versions/casks
        };
        taps  = [ "homebrew/core" "homebrew/cask" "tw93/tap" ];
        brews = [
          "mas"
          "aspell"
          "xcodes"
          "node"
          "ttfautohint"
          "pngpaste"
          "lua-language-server"
          "gh"
					"sing-box"
          "ffmpeg"
          # "yt-dlp"
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
        ];
        casks = [
					"emacs-plus-app@master"
          "thebrowsercompany-dia"
          "google-chrome@dev"
          "tailscale-app"
          "opencode-desktop"
          "orbstack"
          "visual-studio-code"
          "zed"
          "ghostty"
          "windows-app"
          "wakatime"
          "chatgpt"
          "codex"
          "codex-app"
          "claude"
          "conductor"
          "commander"
          "linearmouse"
          "inkscape"
          "figma"
          "zoom"
          "netnewswire"
          # "blender"
          "steam"
          "telegram"
          "mactex"
          "squirrel-app"
          "iina"
          "the-unarchiver"
          "zotero"
          "google-drive"
          "appcleaner"
          "tencent-meeting"
          "microsoft-office"
          "alt-tab"
          "calibre"
          "lyric-fever"
          "spotify"
          # fonts
          "font-lxgw-wenkai"
          "font-jetbrains-mono-nerd-font"
          "font-maple-mono-nf"
          "font-maple-mono-nf-cn"
          "font-juliamono"
          "font-monaspice-nerd-font"
          "font-zed-mono-nerd-font"
          "font-zed-sans"
          "font-literata"
          "font-libre-baskerville"
          "font-source-serif-4"
          "font-geist"
          "font-geist-mono-nerd-font"
        ];
        masApps = {
          Shadowrocket = 932747118;
          infuse = 1136220934;
        };
      };

      system.primaryUser = "fangyuan";
      system.defaults = {
        dock.autohide  = true;
        dock.largesize = 64;
        dock.persistent-apps = [
          "/Applications/Dia.app"
          "/Applications/Ghostty.app"
					"/Applications/Emacs.app"
          "/Applications/Figma.app"
          "/Applications/Spotify.app"
          "/Applications/Zotero.app"
        ];
        # finder settings
        finder.FXPreferredViewStyle = "clmv";
        finder.AppleShowAllExtensions = true;
        finder.AppleShowAllFiles = true;
        finder.NewWindowTarget = "Documents";
        finder.ShowPathbar = true;
        finder.ShowStatusBar = true;
        finder.FXDefaultSearchScope = "SCcf";
        # control center
        controlcenter.BatteryShowPercentage = true;
        # clock
        menuExtraClock.Show24Hour = true;
        menuExtraClock.ShowAMPM = false;
        menuExtraClock.ShowDate = 2;
        menuExtraClock.ShowDayOfMonth = false;
        loginwindow.GuestEnabled  = false;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.KeyRepeat = 2;
        # trackpad settings
        trackpad.Clicking = true;
        trackpad.Dragging = true;
        trackpad.TrackpadThreeFingerDrag = true;
        # hot corner
        dock.wvous-tl-corner = 13;
        # others
        NSGlobalDomain.ApplePressAndHoldEnabled = false;
      };

      # Auto upgrade nix package and the daemon service.
      # services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 4;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#mbp
    darwinConfigurations."mbp" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
	      nix-homebrew.darwinModules.nix-homebrew
        {
          nixpkgs.overlays = [ claude-code.overlays.default ];

          nix-homebrew = {
            enable = true;
            # Apple Silicon Only
            # TODO: this line don't work!
            enableRosetta = true;
            # User owning the Homebrew prefix
            user = "fangyuan";
	          taps = {
	            "d12frosted/homebrew-emacs-plus" = homebrew-emacsplus;
	            "homebrew/homebrew-core" = homebrew-core;
	            "homebrew/homebrew-cask" = homebrew-cask;
	            "tw93/homebrew-tap" = homebrew-tw93;
	          };
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."mbp".pkgs;
  };
}
