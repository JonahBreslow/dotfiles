return {
  { "mbbill/undotree", keys = { { "<leader>u", vim.cmd.UndotreeToggle, desc = "Undotree" } } },
  { "tpope/vim-fugitive", cmd = "Git", keys = { { "<leader>gs", vim.cmd.Git, desc = "Git status" } } },
  { "christoomey/vim-tmux-navigator", event = "VeryLazy" },
}
