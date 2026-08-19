{ lib, ... }:

{
  imports = [
    ../../configuration.nix
    ../../modules/steamstuff.nix
  ] ++ lib.optionals (builtins.pathExists ../../hardware-configuration.nix) [
    ../../hardware-configuration.nix
  ];

  networking.hostName = "boxtop";

  fileSystems."/media" = {
    fsType = "ext4";
    options = [ "nofail" "x-gvfs-show" "x-gvfs-name=Games" ];
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "smoo";
  };
  services.displayManager.defaultSession = "hyprland";
}
