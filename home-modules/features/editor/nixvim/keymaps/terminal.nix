# Terminal Keymaps
# ToggleTerm floating terminal integration
#
# Bindings:
#   <leader>tt - Toggle floating terminal
#   C-\        - Toggle terminal (works from insert mode too)

_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>tt";
      action = "<cmd>ToggleTerm<cr>";
      options = {
        silent = true;
        desc = "Floating terminal";
      };
    }
  ];
}
