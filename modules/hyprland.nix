{ config, pkgs, ... }:

let
  monitorConfigs = {
    boxtop = ../hosts/desktop/monitors.lua;
    braptop = ../hosts/braptop/monitors.lua;
  };
  monitorConfig = monitorConfigs.${config.networking.hostName};
  hyprConfig = pkgs.runCommand "hypr-config" {} ''
    mkdir -p $out
    cp -r ${../dotfiles/hypr}/. $out/
    cp ${monitorConfig} $out/monitors.lua
  '';
in {
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    # Desktop shell / application launcher
    foot
    quickshell
    rofi

    # Session management
    hyprlock
    hypridle
    kanshi

    # Screenshots, clipboard, and notifications
    grim
    slurp
    wl-clipboard
    libnotify

    # Hardware and media controls
    brightnessctl
    playerctl
  ];

  home-manager.users.smoo = {
    xdg.configFile."hypr".source = hyprConfig;

    systemd.user.services.hypridle = {
      Unit = {
        Description = "Hyprland idle daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        Restart = "on-failure";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
