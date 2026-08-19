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
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.smoo = { config, pkgs, ... }: {
    home.stateVersion = "26.05";

    xdg.configFile = {
      "hypr".source = hyprConfig;
      "quickshell".source = ../dotfiles/quickshell;
      "foot".source = ../dotfiles/foot;
      "nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Projects/nix-dots/dotfiles/nvim";
    };

    xdg.userDirs = {
      enable = true;
      createDirectories = true;

      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      projects = "${config.home.homeDirectory}/Projects";
      videos = "${config.home.homeDirectory}/Videos";

      extraConfig.XDG_WORK_DIR = "${config.home.homeDirectory}/Work";
    };

    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Yaru-blue";
        package = pkgs.yaru-theme;
      };
      cursorTheme = {
        name = "Yaru";
        package = pkgs.yaru-theme;
        size = 24;
      };
    };

    programs.bash = {
      enable = true;
      enableCompletion = true;

      shellAliases = {
        rebuild = "sudo nixos-rebuild switch --flake 'path:/home/smoo/Projects/nix-dots#desktop'";
        rebuild-laptop = "sudo nixos-rebuild switch --flake 'path:/home/smoo/Projects/nix-dots#braptop'";
        vim = "nvim";
        c = "opencode";
        ls = "eza -lh --group-directories-first --icons=auto";
        lsa = "ls -a";
        lt = "eza --tree --level=2 --long --icons --git";
        lta = "lt -a";
      };

      bashrcExtra = ''
        export EDITOR=nvim
        bind 'set completion-ignore-case on'
        bind 'set completion-map-case on'
        bind 'set show-all-if-ambiguous on'

        git_prompt() {
          local branch dirty=""
          branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)" || return
          [[ -n "$(git status --porcelain 2>/dev/null)" ]] && dirty=" ●"
          printf ' %s%s' "$branch" "$dirty"
        }

        PS1='\[\e[1;38;2;129;152;144m\]\w\[\e[3m\]$(git_prompt)\[\e[23m\] \[\e[1;38;2;165;181;171m\]❯ \[\e[0m\]'
      '';
    };

    programs.eza = {
      enable = true;
      icons = "auto";
      git = true;
    };

    programs.git = {
      enable = true;
      settings.user = {
        name = "phil";
        email = "philvellacott@proton.me";
      };
    };

    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "image/jpeg" = [ "imv.desktop" ];
        "image/png" = [ "imv.desktop" ];
        "image/gif" = [ "imv.desktop" ];
        "image/webp" = [ "imv.desktop" ];
        "image/bmp" = [ "imv.desktop" ];
        "image/tiff" = [ "imv.desktop" ];
        "image/svg+xml" = [ "imv.desktop" ];

        "video/mp4" = [ "mpv.desktop" ];
        "video/x-matroska" = [ "mpv.desktop" ];
        "video/x-msvideo" = [ "mpv.desktop" ];
        "video/webm" = [ "mpv.desktop" ];
        "video/quicktime" = [ "mpv.desktop" ];
        "video/mpeg" = [ "mpv.desktop" ];
      };
    };

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
