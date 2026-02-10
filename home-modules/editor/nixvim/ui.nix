_: {
  programs.nixvim.plugins = {
    # Enhanced statusline with clean, minimal design
    lualine = {
      enable = true;
      settings = {
        options = {
          globalstatus = true;
          component_separators = {
            left = "";
            right = "";
          };
          section_separators = {
            left = "";
            right = "";
          };
          theme = "auto";
        };
        sections = {
          lualine_a = ["mode"];
          lualine_b = ["branch" "diff"];
          lualine_c = [
            {
              __unkeyed-1 = "filename";
              path = 1; # Show relative path
            }
          ];
          lualine_x = [
            {
              __unkeyed-1 = "diagnostics";
              sources = ["nvim_lsp"];
              symbols = {
                error = " ";
                warn = " ";
                info = " ";
                hint = "󰌵 ";
              };
            }
            "encoding"
            "fileformat"
            "filetype"
          ];
          lualine_y = ["progress"];
          lualine_z = ["location"];
        };
      };
    };

    # Buffer tabs with LSP diagnostics
    bufferline = {
      enable = true;
      settings = {
        options = {
          mode = "buffers";
          diagnostics = "nvim_lsp";
          separator_style = "slant";
          show_buffer_close_icons = false;
          show_close_icon = false;
          offsets = [
            {
              filetype = "neo-tree";
              text = "File Explorer";
              text_align = "center";
              separator = true;
            }
          ];
          diagnostics_indicator = ''
            function(count, level, diagnostics_dict, context)
              local icon = level:match("error") and " " or " "
              return " " .. icon .. count
            end
          '';
        };
      };
    };

    # Modern notification system
    notify = {
      enable = true;
      settings = {
        timeout = 3000;
        top_down = true;
        render = "compact";
        stages = "fade";
      };
    };

    # Better diagnostic UI
    trouble = {
      enable = true;
      settings = {
        auto_close = true;
        auto_open = false;
        use_diagnostic_signs = true;
      };
    };

    # Start screen with modern dashboard layout
    alpha = {
      enable = true;
      settings.layout = [
        {
          type = "padding";
          val = 2;
        }
        {
          type = "text";
          val = [
            "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
            "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
            "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
            "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
            "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
            "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
          ];
          opts = {
            position = "center";
            hl = "Type";
          };
        }
        {
          type = "padding";
          val = 2;
        }
        {
          type = "text";
          val = "╭────────────────────────────────────────╮";
          opts = {
            position = "center";
            hl = "AlphaFooter";
          };
        }
        {
          type = "text";
          val = "│          Quick Actions                 │";
          opts = {
            position = "center";
            hl = "SpecialComment";
          };
        }
        {
          type = "text";
          val = "├────────────────────────────────────────┤";
          opts = {
            position = "center";
            hl = "AlphaFooter";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "group";
          val = [
            {
              type = "button";
              val = "󰈔  Find File";
              on_press = {
                __raw = "function() require('telescope.builtin').find_files() end";
              };
              opts = {
                shortcut = "f";
                position = "center";
                cursor = 3;
                width = 40;
                align_shortcut = "right";
                hl = "AlphaButtons";
                hl_shortcut = "AlphaShortcut";
              };
            }
            {
              type = "button";
              val = "󰋚  Recent Files";
              on_press = {
                __raw = "function() require('telescope.builtin').oldfiles() end";
              };
              opts = {
                shortcut = "r";
                position = "center";
                cursor = 3;
                width = 40;
                align_shortcut = "right";
                hl = "AlphaButtons";
                hl_shortcut = "AlphaShortcut";
              };
            }
            {
              type = "button";
              val = "󰱼  Find Text";
              on_press = {
                __raw = "function() require('telescope.builtin').live_grep() end";
              };
              opts = {
                shortcut = "g";
                position = "center";
                cursor = 3;
                width = 40;
                align_shortcut = "right";
                hl = "AlphaButtons";
                hl_shortcut = "AlphaShortcut";
              };
            }
          ];
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "text";
          val = "├────────────────────────────────────────┤";
          opts = {
            position = "center";
            hl = "AlphaFooter";
          };
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "group";
          val = [
            {
              type = "button";
              val = "󰐥  Quit Neovim";
              on_press = {
                __raw = "function() vim.cmd('qa') end";
              };
              opts = {
                shortcut = "q";
                position = "center";
                cursor = 3;
                width = 40;
                align_shortcut = "right";
                hl = "AlphaButtons";
                hl_shortcut = "AlphaShortcut";
              };
            }
          ];
        }
        {
          type = "padding";
          val = 1;
        }
        {
          type = "text";
          val = "╰────────────────────────────────────────╯";
          opts = {
            position = "center";
            hl = "AlphaFooter";
          };
        }
        {
          type = "padding";
          val = 2;
        }
      ];
    };
  };
}
