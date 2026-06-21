vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim", "https://github.com/nvim-tree/nvim-web-devicons" })

require("lualine").setup({
  sections = {
    lualine_c = {
      {
        "filename",
        path = 1,
      },
    },
    lualine_x = {
      {
        "macro",
        fmt = function()
          local reg = vim.fn.reg_recording()
          if reg ~= "" then
            return "Recording @" .. reg
          end
          return nil
        end,
        color = { fg = "#ff9e64" },
        draw_empty = false,
      },
      "encoding",
      "fileformat",
      "filetype",
      -- 'lsp_status',
    },
  },
})
