_: {
  programs.nixvim.keymaps = [
    # Bufferline navigation
    {
      mode = "n";
      key = "<Tab>";
      action = "<cmd>BufferLineCycleNext<cr>";
      options = {
        silent = true;
        desc = "Next buffer";
      };
    }
    {
      mode = "n";
      key = "<S-Tab>";
      action = "<cmd>BufferLineCyclePrev<cr>";
      options = {
        silent = true;
        desc = "Previous buffer";
      };
    }
    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<cr>";
      options = {
        silent = true;
        desc = "Delete buffer";
      };
    }
    {
      mode = "n";
      key = "<leader>bp";
      action = "<cmd>BufferLinePick<cr>";
      options = {
        silent = true;
        desc = "Pick buffer";
      };
    }
  ];
}
