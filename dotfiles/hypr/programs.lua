---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local programs = {
    terminal    = [[foot --working-directory="$(bash "$HOME/.config/hypr/scripts/terminal-cwd")"]],
    fileManager = "thunar",
    menu        = "rofi -show drun",
    browser     = "firefox",
}

return programs
