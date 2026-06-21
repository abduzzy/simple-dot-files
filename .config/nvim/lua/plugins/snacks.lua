vim.pack.add({
  "https://github.com/folke/snacks.nvim",
})

local Snacks = require("snacks")
Snacks.setup({
  animate = { enabled = false },
  bigfile = { enabled = true },
  toggle = {},
  words = { enabled = false },
  scroll = { enabled = false },

  picker = {
    enabled = true,
    win = {
      input = {
        keys = {
          ["<a-H>"] = { "toggle_hidden", mode = { "i", "n" } },
        },
      },
    },
  },
})

-- configure buffer keymap
vim.keymap.set("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete current buffer" })
vim.keymap.set("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete other buffers" })

-- configure ui keymap
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
Snacks.toggle.line_number():map("<leader>ul")

Snacks.toggle.animate():map("<leader>ua")

if vim.lsp.inlay_hint then
  Snacks.toggle.inlay_hints():map("<leader>uh")
end

Snacks.toggle.zen():map("<leader>uz")
-- terminal
vim.keymap.set("n", "<leader>ut", function()
  Snacks.terminal()
end, { desc = "Terminal" })

-- configure picker keymaps
vim.keymap.set("n", "<leader><leader>", function()
  Snacks.picker.buffers()
end, {
  desc = "[ ] Find existing buffers",
})
vim.keymap.set("n", "<leader>sH", function()
  Snacks.picker.help()
end, {
  desc = "[S]earch [H]elp",
})
vim.keymap.set("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, {
  desc = "[S]earch [K]eymap",
})
vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.files()
end, {
  desc = "[S]earch [F]iles",
})
vim.keymap.set("n", "<leader>sg", function()
  Snacks.picker.grep()
end, {
  desc = "[S]earch by [G]rep",
})
vim.keymap.set("n", "<leader>sN", function()
  Snacks.picker.notifications()
end, {
  desc = "[S]earch [N]otifications",
})
vim.keymap.set("n", "<leader>sw", function()
  Snacks.picker.grep_word()
end, {
  desc = "[S]earch current [W]ord",
})
vim.keymap.set("n", "<leader>sd", function()
  Snacks.picker.diagnostics()
end, {
  desc = "[S]earch [D]iagnostics",
})
vim.keymap.set("n", "<leader>sr", function()
  Snacks.picker.resume()
end, {
  desc = "[S]earch [R]esume",
})
vim.keymap.set("n", "<leader>sC", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, {
  desc = "[S]earch Neovim [C]onfig files",
})
vim.keymap.set("n", "<leader>s.", function()
  Snacks.picker.recent()
end, {
  desc = "[S]earch Recent Files",
})
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.recent()
end, {
  desc = "[/] Fuzzily search in current buffer",
})
