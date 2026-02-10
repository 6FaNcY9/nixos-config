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
      action = ''
        <cmd> lua require("telescope.builtin").keymaps(
          require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
            layout_config = { width = 0.80, height = 0.70},
          })
        )<cr>
      '';
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
