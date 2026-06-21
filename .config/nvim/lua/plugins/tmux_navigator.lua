vim.pack.add({
  "https://github.com/christoomey/vim-tmux-navigator",
})

local modes = { "n", "v", "s" }

vim.keymap.set(modes, "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>")
vim.keymap.set(modes, "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>")
vim.keymap.set(modes, "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>")
vim.keymap.set(modes, "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>")

vim.keymap.set(modes, "<c-w>h", "<c-h>", { remap = true })
vim.keymap.set(modes, "<c-w>j", "<c-j>", { remap = true })
vim.keymap.set(modes, "<c-w>k", "<c-k>", { remap = true })
vim.keymap.set(modes, "<c-w>l", "<c-l>", { remap = true })
