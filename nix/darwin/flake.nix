{
  description = "FY's flakes of nix-darwin";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    homebrew-emacsplus = {
      url = "github:d12frosted/homebrew-emacs-plus";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-emacsplus }:
  let
    configuration = { pkgs, config, ... }: {

      nix.enable = true;
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
          pkgs.p7zip
        ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
          "emacs-plus@30"
          "aspell"
          "xcodes"
          "pngpaste"
        ];
        casks = [
          # development
          "alacritty"
          "google-chrome"
          "orbstack"
          "visual-studio-code"
          "zed"
          "ghostty"
          "cursor"
          "wakatime"
          "chatwise"
          # graphics
          "gimp"
          "inkscape"
          "figma"
          "blender"
          # game
          "steam"
          # other
          "logi-options+"
          "mactex"
          "squirrel"
          "iina"
          "the-unarchiver"
          "zotero@beta"
          "google-drive"
          "appcleaner"
          "tencent-meeting"
          "microsoft-office"
          "alt-tab"
          "calibre"
          "lyric-fever"
          "dingtalk"
          # "free-download-manager"
          # "motrix"
          # fonts
          "font-lxgw-wenkai"
          "font-ibm-plex-sans"
          "font-ibm-plex-sans-sc"
          "font-ibm-plex-sans-arabic"
          "font-ibm-plex-mono"
          "font-ibm-plex-math"
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

      # TODO: This symlink the apps, won't shown in spotlight
      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      system.defaults = {
        dock.autohide  = true;
        dock.largesize = 64;
        dock.persistent-apps = [
          "/System/Applications/Launchpad.app"
          "/System/Cryptexes/App/System/Applications/Safari.app"
          # "${pkgs.alacritty}/Applications/Alacritty.app"
          "/Applications/Ghostty.app"
          "/opt/homebrew/Cellar/emacs-plus@30/30.0.93/Emacs.app"
          "/System/Applications/Music.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/Applications/Zotero.app"
        ];
        finder.FXPreferredViewStyle = "clmv";
        loginwindow.GuestEnabled  = false;
        NSGlobalDomain.AppleICUForce24HourTime = true;
        NSGlobalDomain.KeyRepeat = 2;
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
    # $ darwin-rebuild build --flake .#mini
    darwinConfigurations."mini" = nix-darwin.lib.darwinSystem {
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
	    };
          };
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."mini".pkgs;
  };
}
