{ ... }:

{
  users.users.fangyuan = {
    isNormalUser = true;
    description = "fangyuan";
    extraGroups = [ "networkmanager" "wheel" ];
  };
}
