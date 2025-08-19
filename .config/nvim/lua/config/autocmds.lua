-- Auto-save
vim.api.nvim_create_autocmd({"FocusLost", "BufLeave"}, {
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command("silent update")
    end
  end,
})