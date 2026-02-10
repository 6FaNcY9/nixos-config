_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<cr>";
      options = {
        silent = true;
        desc = "Find files";
      };
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>Telescope live_grep<cr>";
      options = {
        silent = true;
        desc = "Live grep";
      };
    }
    {
      mode = "n";
      key = "<leader>fb";
      action = "<cmd>Telescope buffers<cr>";
      options = {
        silent = true;
        desc = "Buffers";
      };
    }
    {
      mode = "n";
      key = "<leader>fh";
      action = "<cmd>Telescope help_tags<cr>";
      options = {
        silent = true;
        desc = "Help tags";
      };
    }
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
      key = "<leader>fk";
      action = "<cmd>Telescope keymaps<cr>";
      options = {
        silent = true;
        desc = "Keymaps";
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
      key = "<leader>tt";
      action = "<cmd>ToggleTerm<cr>";
      options = {
        silent = true;
        desc = "Floating terminal";
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
      key = "<leader>fc";
      action = "<cmd>Telescope commands<cr>";
      options = {
        silent = true;
        desc = "Commands";
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
