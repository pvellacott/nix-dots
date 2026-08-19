{ lib, ... }:

{
  imports = [
    ../../configuration.nix
  ] ++ lib.optionals (builtins.pathExists ../../hardware-configuration.nix) [
    ../../hardware-configuration.nix
  ];

  networking.hostName = "boxtop";

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/YOUR-LUKS-UUID";

  services.displayManager.autoLogin = {
    enable = true;
    user = "smoo";
  };
  services.displayManager.defaultSession = "hyprland";
}
