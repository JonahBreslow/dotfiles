vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", function()
    vim.cmd("w")
    vim.cmd("Ex")
end, {noremap = true, silent = true })
vim.api.nvim_set_keymap('i',  'jk', '<Esc>', { noremap = true, silent = true })
vim.keymap.set({'n', 'v'} , 'y', '"+y', {noremap = true, silent = true})
-- window toggles
vim.keymap.set('n', '<leader>h', '<C-w>h', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>j', '<C-w>j', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>k', '<C-w>k', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>l', '<C-w>l', { noremap = true, silent = true })
