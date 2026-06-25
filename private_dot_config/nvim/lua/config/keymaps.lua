-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

map("n", "<leader>uA", function()
  vim.b.autoformat = not LazyVim.format.enabled(0)
  vim.notify("Buffer autoformat " .. (vim.b.autoformat and "enabled" or "disabled"))
end, { desc = "Toggle Buffer Autoformat" })
