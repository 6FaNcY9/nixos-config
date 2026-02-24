_: {
  programs.nixvim.keymaps = [
    {
      mode = "i";
      key = "<M-l>";
      action = "<cmd>lua require('copilot.suggestion').accept()<cr>";
      options = {
        silent = true;
        desc = "Copilot: accept Copilot";
      };
    }
    {
      mode = "i";
      key = "<M-w>";
      action = "<cmd>lua require('copilot.suggestion').accept_word()<cr>";
      options = {
        silent = true;
        desc = "Copilot: accept word";
      };
    }
    {
      mode = "i";
      key = "<M-j>";
      action = "<cmd>lua require('copilot.suggestion').accept_line()<cr>";
      options = {
        silent = true;
        desc = "Copilot: accept line";
      };
    }
    {
      mode = "i";
      key = "<M-[>";
      action = "<cmd>lua require('copilot.suggestion').next()<cr>";
      options = {
        silent = true;
        desc = "Copilot: next suggestion";
      };
    }
    {
      mode = "i";
      key = "<M-]>";
      action = "<cmd>lua require('copilot.suggestion').prev()<cr>";
      options = {
        silent = true;
        desc = "Copilot: previous suggestion";
      };
    }
    {
      mode = "i";
      key = "<M-\\>";
      action = "<cmd>lua require('copilot.suggestion').dismiss()<cr>";
      options = {
        silent = true;
        desc = "Copilot: dismiss suggestion";
      };
    }
    {
      mode = "n";
      key = "<leader>ap";
      action = "<cmd>Copilot panel<cr>";
      options = {
        silent = true;
        desc = "Copilot: open panel";
      };
    }
  ];
}
