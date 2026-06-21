vim.pack.add({
  {
    src = "https://github.com/NMAC427/guess-indent.nvim",
    name = "guess-indent",
  },
  {
    src = "https://github.com/lukas-reineke/indent-blankline.nvim",
    name = "indent-blankline",
  },
})

require("guess-indent").setup({})
require("ibl").setup({})
