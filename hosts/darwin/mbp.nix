{ self, ... }:

{
  imports = [
    ../../modules/darwin/nix.nix
    ../../modules/darwin/packages.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/defaults.nix
    ../../modules/darwin/dock.nix
    ../../modules/darwin/shells.nix
  ];

  system.primaryUser = "fangyuan";
  users.users.fangyuan.home = "/Users/fangyuan";
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.stateVersion = 4;

  nixpkgs.hostPlatform = "aarch64-darwin";
}
