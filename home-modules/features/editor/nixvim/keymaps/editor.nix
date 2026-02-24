_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>ft";
      action = "<cmd>Tutor<cr>";
      options = {
        silent = true;
        desc = "Tutor";
      };
    }
    {
      mode = "n";
      key = "<leader>?";
      action = "<cmd>Cheatsheet<cr>";
      options = {
        silent = true;
        desc = "Cheatsheet";
      };
    }
    {
      mode = "n";
      key = "<leader>fe";
      action = "<cmd>Neotree toggle<cr>";
      options = {
        silent = true;
        desc = "Toggle tree";
      };
    }
    {
      mode = "n";
      key = "<leader>fm";
      action = "<cmd>lua vim.lsp.buf.format({ async = true })<cr>";
      options = {
        silent = true;
        desc = "Format";
      };
    }
    {
      mode = "n";
      key = "<leader>pm";
      action = "<cmd>Markview toggle<cr>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>pr";
      action = "<cmd>Markview render<cr>";
      options = {
        noremap = true;
        silent = true;
      };
    }
  ];
}
