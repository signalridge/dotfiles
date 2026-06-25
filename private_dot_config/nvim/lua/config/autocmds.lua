-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local group = vim.api.nvim_create_augroup("local_dotfiles", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = group,
  pattern = { "*.tmpl", "*.chezmoitmpl" },
  callback = function(event)
    vim.b[event.buf].autoformat = false
  end,
  desc = "Keep formatters from rewriting chezmoi templates",
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "gitcommit", "markdown" },
  callback = function(event)
    vim.bo[event.buf].textwidth = 100
  end,
  desc = "Use a practical prose width for docs and commits",
})
