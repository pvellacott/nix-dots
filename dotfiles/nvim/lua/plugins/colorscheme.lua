return {
  -- Theme stolen from Dos-Moos.
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      transparent = false,
      colors = {
        bg = "#131516",
        dark_bg = "#131516",
        darker_bg = "#0F1011",
        lighter_bg = "#273236",

        fg = "#F8EBE3",
        dark_fg = "#A5B5AB",
        light_fg = "#F9F5E4",
        bright_fg = "#F9F5E4",
        muted = "#72856C",

        red = "#F0334A",
        orange = "#E0C15C",
        yellow = "#F4E276",
        green = "#B8CE76",
        cyan = "#6d877d",
        blue = "#A5B5AB",
        purple = "#8FB87A",
        brown = "#72856C",

        bright_red = "#F0334A",
        bright_yellow = "#F4E276",
        bright_green = "#B8CE76",
        bright_cyan = "#6d877d",
        bright_blue = "#A5B5AB",
        bright_purple = "#8FB87A",

        accent = "#819890",
        cursor = "#F4E276",
        foreground = "#F8EBE3",
        background = "#131516",
        selection = "#59594B",
        selection_foreground = "#F8EBE3",
        selection_background = "#131516",
      },
      on_highlights = function(hl, c)
        hl.CursorLine = { bg = "#1F2629" }
        hl.CursorLineNr = { fg = c.yellow, bold = true }
        hl.LspReferenceText = { bg = c.selection, fg = c.bright_fg }
        hl.LspReferenceRead = hl.LspReferenceText
        hl.LspReferenceWrite = hl.LspReferenceText
        hl.SnacksPickerDir = { fg = c.muted }
        hl.SnacksPickerPathHidden = { fg = c.muted }
        hl.SnacksPickerPathIgnored = { fg = c.muted }
        hl.SnacksPickerListCursorLine = { bg = "#1F2629" }
      end,
    },
    config = function(_, opts)
      require("aether").setup(opts)
      vim.cmd.colorscheme("aether")
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}
