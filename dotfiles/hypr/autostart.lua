return function(programs)
    -------------------
    ---- AUTOSTART ----
    -------------------

    -- See https://wiki.hypr.land/Configuring/Basics/Autostart/

    -- Autostart necessary processes (like notifications daemons, status bars, etc.)
    -- Or execute your favorite apps at launch like this:
    --
    -- hl.on("hyprland.start", function () 
    --   hl.exec_cmd(programs.terminal)
    --   hl.exec_cmd("nm-applet")
    --   hl.exec_cmd("waybar & hyprpaper & firefox")
    -- end)
end
