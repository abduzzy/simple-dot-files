vim.pack.add({ "https://github.com/mikavilpas/yazi.nvim" })

require("yazi").setup({
  open_for_directories = true,
  keymaps = {
    show_help = "<f1>",
  },
})

vim.keymap.set({ "n", "v" }, "-", "<cmd>Yazi<cr>", {
  desc = "Open yazi at the current file",
})
