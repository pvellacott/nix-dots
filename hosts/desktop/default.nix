{ lib, ... }:

{
  imports = [
    ../../configuration.nix
    ../../modules/readyplayerone.nix
  ] ++ lib.optionals (builtins.pathExists ../../hardware-configuration.nix) [
    ../../hardware-configuration.nix
  ];

  networking.hostName = "boxtop";

  # Only adding this because my desktop MediaTek controller which it thinks has bluetooth.
  # Don't want the daemon to spin up
  hardware.bluetooth.enable = lib.mkForce false;
  hardware.bluetooth.powerOnBoot = lib.mkForce false;

  # Desktop specific programs
  programs.obs-studio.enable = true;

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
