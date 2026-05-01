-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ESC shortcuts
vim.api.nvim_set_keymap("i", "jj", "<ESC>", { noremap = false })
vim.api.nvim_set_keymap("i", "jk", "<ESC>", { noremap = false })

-- Which-key keymaps
local wk = require 'which-key'

-- Vim-Visual-Multi keymaps
local function visual_cursors_with_delay()
    -- Execute the vm-visual-cursors command.
    vim.cmd 'silent! execute "normal! \\<Plug>(VM-Visual-Cursors)"'
    -- Introduce delay via VimScript's 'sleep' (set to 500 milliseconds here).
    vim.cmd 'sleep 200m'
    -- Press 'A' in normal mode after the delay.
    vim.cmd 'silent! execute "normal! A"'
end

wk.add {
    { '<leader>m', group = 'Visual Multi' },
    { '<leader>ma', '<Plug>(VM-Select-All)<Tab>', desc = 'Select All', mode = 'n' },
    { '<leader>mr', '<Plug>(VM-Start-Regex-Search)', desc = 'Start Regex Search', mode = 'n' },
    { '<leader>mp', '<Plug>(VM-Add-Cursor-At-Pos)', desc = 'Add Cursor At Pos', mode = 'n' },
    { '<leader>mv', visual_cursors_with_delay, desc = 'Visual Cursors', mode = 'v' },
    { '<leader>mo', '<Plug>(VM-Toggle-Mappings)', desc = 'Toggle Mapping', mode = 'n' },
}

-- Save without formatting
vim.keymap.set("n", "<leader>fs", function()
  -- Helper function to handle the actual save safely
  local function do_save(cmd)
    local current_format_state = vim.b.autoformat
    vim.b.autoformat = false
    local success, err = pcall(vim.cmd, cmd)
    vim.b.autoformat = current_format_state

    if not success then
      local clean_err = string.match(err, "E%d+:.*") or err
      vim.api.nvim_err_writeln(clean_err)
    end
  end

  -- Check if the current buffer has a file name
  if vim.api.nvim_buf_get_name(0) == "" then
    -- It's a new, unnamed buffer: prompt for a name
    vim.ui.input({ prompt = "Save as: " }, function(input)
      -- If you type a name and press Enter, save it. (Skips if you press Esc)
      if input and input ~= "" then
        do_save("write " .. input)
      end
    end)
  else
    -- It's an existing file: just save it
    do_save("write")
  end
end, { desc = "Save without formatting" })

