{
  description = "Fangyuan dotfiles and Nix configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    brew-src = {
      url = "github:Homebrew/brew";
      flake = false;
    };

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.brew-src.follows = "brew-src";
    };

    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, nix-homebrew, claude-code, ... }:
    let
      username = "fangyuan";
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = linuxSystem;
        specialArgs = { inherit self inputs username; };
        modules = [
          ./hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./home/nixos.nix;
          }
        ];
      };

      homeConfigurations.fangyuan-ubuntu = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = linuxSystem;
          config.allowUnfree = true;
        };
        extraSpecialArgs = { inherit self inputs username; };
        modules = [ ./home/ubuntu.nix ];
      };

      darwinConfigurations.mbp = nix-darwin.lib.darwinSystem {
        system = darwinSystem;
        specialArgs = { inherit self inputs username; };
        modules = [
          ./hosts/darwin/mbp.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            nixpkgs.overlays = [ claude-code.overlays.default ];

            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
              mutableTaps = true;
            };

            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.users.${username} = import ./home/darwin.nix;
          }
        ];
      };
    };
}
