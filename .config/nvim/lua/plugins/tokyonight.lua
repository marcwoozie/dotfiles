return {
  {
    "folke/tokyonight.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl)
        hl.Normal = { bg = "none" }
        hl.NormalNC = { bg = "none" }
        hl.SignColumn = { bg = "none" }
        hl.EndOfBuffer = { bg = "none" }
        hl.FloatBorder = { bg = "none" }
        hl.NormalFloat = { bg = "none" }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd([[colorscheme tokyonight]])
    end,
  },
}
