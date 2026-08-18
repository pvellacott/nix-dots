{ lib, pkgs, areYaGaminSon ? false, ... }:

lib.mkIf areYaGaminSon {
  # AMD gaming PC only: Steam, Gamescope, GameMode, and 32-bit graphics support.
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope
    mangohud
    protonup-qt
    vulkan-tools
    mesa-demos
  ];
}
