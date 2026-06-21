vim.pack.add({
  "https://github.com/folke/trouble.nvim",
})

require("trouble").setup({
  modes = {
    lsp = {
      win = { position = "right" },
    },
    test = {
      mode = "diagnostics",
      preview = {
        type = "split",
        relative = "win",
        position = "right",
        size = 0.3,
      },
    },
  },
})

vim.keymap.set("n", "<leader>dd", "<cmd>Trouble diagnostics toggle<cr>", { desc = "[d]iagnostics" })
vim.keymap.set("n", "<leader>dD", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer [D]iagnostics" })
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "[d]iagnostics [s]ymbols" })
vim.keymap.set("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "[d]iagnostics l[S]p/definitions/..." })
vim.keymap.set("n", "<leader>dL", "<cmd>Trouble loclist toggle<cr>", { desc = "[d]iagnostics [L]ocation list" })
vim.keymap.set("n", "<leader>dQ", "<cmd>Trouble qflist toggle<cr>", { desc = "[d]iagnostics [Q]uickfix list" })

vim.keymap.set("n", "[q", function()
  if require("trouble").is_open() then
    require("trouble").prev({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cprev)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, { desc = "Previous Trouble/Quickfix Item" })

vim.keymap.set("n", "]q", function()
  if require("trouble").is_open() then
    require("trouble").next({ skip_groups = true, jump = true })
  else
    local ok, err = pcall(vim.cmd.cnext)
    if not ok then
      vim.notify(err, vim.log.levels.ERROR)
    end
  end
end, { desc = "Next Trouble/Quickfix Item" })
