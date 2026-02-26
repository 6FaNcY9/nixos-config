# LSP Keymaps
# Trouble.nvim integration for better diagnostic UX
#
# Bindings:
#   <leader>xx - Trouble diagnostics toggle (workspace-wide)
#   <leader>xd - Trouble diagnostics for current buffer
#   <leader>xl - Trouble location list
#   <leader>xq - Trouble quickfix list

_: {
  programs.nixvim.keymaps = [
    # Trouble diagnostics
    {
      mode = "n";
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<cr>";
      options = {
        silent = true;
        desc = "Diagnostics (Trouble)";
      };
    }
    {
      mode = "n";
      key = "<leader>xd";
      action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
      options = {
        silent = true;
        desc = "Buffer Diagnostics (Trouble)";
      };
    }
    {
      mode = "n";
      key = "<leader>xl";
      action = "<cmd>Trouble loclist toggle<cr>";
      options = {
        silent = true;
        desc = "Location List (Trouble)";
      };
    }
    {
      mode = "n";
      key = "<leader>xq";
      action = "<cmd>Trouble qflist toggle<cr>";
      options = {
        silent = true;
        desc = "Quickfix List (Trouble)";
      };
    }
  ];
}
