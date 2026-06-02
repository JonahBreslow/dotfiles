return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "python", "c", "lua", "vim", "vimdoc", "query", "markdown", "markdown_inline" },
      })
    end,
  },
}
