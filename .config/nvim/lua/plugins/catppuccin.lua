vim.pack.add({ { src = "https://github.com/catppuccin/nvim", name = "catppuccin" } })

-- configure catppuccin theme
require("catppuccin").setup({
  flavour = "mocha",
  transparent_background = true,
  styles = {
    functions = { "italic" },
    types = { "italic", "bold" },
    loops = { "italic" },
    comments = { "italic" },
    conditionals = { "italic" },
    booleans = { "italic" },
    variables = { "italic" },
  },
})

vim.cmd.colorscheme("catppuccin")
