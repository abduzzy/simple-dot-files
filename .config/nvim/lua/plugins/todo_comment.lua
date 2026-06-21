vim.pack.add({ "https://github.com/folke/todo-comments.nvim" })

require("todo-comments").setup({
  signs = false,
})

local Snacks = require("snacks")

vim.keymap.set("n", "<leader>st", function()
  Snacks.picker.todo_comments({ keywords = { "TODO" } })
end, {
  desc = "[S]earch [t]odo",
})

vim.keymap.set("n", "<leader>sT", function()
  Snacks.picker.todo_comments()
end, {
  desc = "[S]earch all [T]odo/Fix/Hack/Note/Warn/Perf",
})
