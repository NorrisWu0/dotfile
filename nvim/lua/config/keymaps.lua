-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Override <leader><leader> to always search from launch cwd (not buffer root)
vim.keymap.set("n", "<leader><leader>", function()
  Snacks.picker.files({ cwd = vim.fn.getcwd() })
end, { desc = "Find Files (cwd)" })
