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
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-emacsplus, homebrew-core, homebrew-cask }:
  let
    configuration = { pkgs, config, ... }: {

      nix.enable = false;
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.stow
          pkgs.git
          pkgs.mkalias
          pkgs.neovim
          pkgs.tmux
          pkgs.fzf
          pkgs.hugo
          pkgs.coreutils
          pkgs.dict
          pkgs.cloudflared
          pkgs.nodejs_23
          pkgs.yarn
          pkgs.aria2
          pkgs.hledger
          pkgs.uv
          pkgs.wget
          pkgs.ghostscript
          pkgs.pdf2svg
        ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
          "emacs-plus@30"
          "aspell"
          "xcodes"
          # "pngpaste"
        ];
        casks = [
          # development
          # "alacritty"
          "google-chrome"
          # "orbstack"
          "visual-studio-code"
          "zed"
          "ghostty"
          # "cursor"
          "wakatime"
          "chatwise"
          "chatgpt"
          "linearmouse"
          # graphics
          "gimp"
          "inkscape"
          # "figma"
          # "blender"
          # game
          "steam"
          # other
          "logi-options+"
          "mactex"
          "squirrel"
          "iina"
          "the-unarchiver"
          "zotero"
          "google-drive"
          "appcleaner"
          "tencent-meeting"
          "microsoft-office"
          "alt-tab"
          "calibre"
          # fonts
          "font-lxgw-wenkai"
          "font-jetbrains-mono-nerd-font"
          "font-maple-mono"
          "font-maple-mono-nf"
          "font-maple-mono-cn"
          "font-maple-mono-nf-cn"
        ];
        masApps = {
          infuse = 1136220934;
          opencat = 6445999201;
          WeChat = 836500024;
          WhatsApp = 310633997;
          # from Sindre Sorhus
          PlainTextEditor = 1572202501;
          PurePaste = 1611378436;
          OneThing = 1604176982;
          Gifski = 1351639930;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      system.defaults = {
        dock.autohide  = true;
        dock.largesize = 64;
        dock.persistent-apps = [
          "/System/Applications/Launchpad.app"
          "/System/Cryptexes/App/System/Applications/Safari.app"
          "/Applications/Ghostty.app"
          "/opt/homebrew/Cellar/emacs-plus@30/30.1/Emacs.app"
          "/System/Applications/Music.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
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
	    };
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."mbp".pkgs;
  };
}
