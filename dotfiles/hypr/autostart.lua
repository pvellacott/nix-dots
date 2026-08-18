return function(programs)
    -------------------
    ---- AUTOSTART ----
    -------------------

    -- See https://wiki.hypr.land/Configuring/Basics/Autostart/

    -- Autostart necessary processes (like notifications daemons, status bars, etc.)
    -- Or execute your favorite apps at launch like this:
    --
    hl.on("hyprland.start", function ()
        hl.exec_cmd("command -v quickshell >/dev/null 2>&1 && quickshell -p ~/.config/quickshell")
        hl.exec_cmd("command -v hypridle >/dev/null 2>&1 && hypridle")
    end)
end
