{ ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitchExternalPower = "ignore";
  };

  services.openssh.enable = true;
  services.tailscale.enable = true;
}
