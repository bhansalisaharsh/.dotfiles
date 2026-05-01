return {
  {
    "mg979/vim-visual-multi",
    lazy = false, -- Set to false to ensure it loads correctly with LazyVim
    config = function()
      -- -- Optional: Add your custom configuration options here
      -- vim.g.VM_maps = {
      --   ["<C-d>"] = "Add Line Down", -- Example custom keymap
      -- }
      vim.g.VM_default_mappings = 0
      vim.g.VM_maps = {
        ['Find Under'] = ''
      }
      vim.g.VM_add_cursor_at_pos_no_mappings = 1
    end,
  },
}

