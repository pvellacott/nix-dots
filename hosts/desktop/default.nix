{ lib, ... }:

{
  imports = [
    ../../configuration.nix
    ../../modules/steamstuff.nix
  ] ++ lib.optionals (builtins.pathExists ../../hardware-configuration.nix) [
    ../../hardware-configuration.nix
  ];

  networking.hostName = "boxtop";

  services.displayManager.autoLogin = {
    enable = true;
    user = "smoo";
  };
  services.displayManager.defaultSession = "hyprland";
}
