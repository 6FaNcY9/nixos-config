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
