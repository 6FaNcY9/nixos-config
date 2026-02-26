# UI Plugins Configuration
# Status line, buffer tabs, notifications, diagnostics, and startup dashboard

_: {
  programs.nixvim.plugins = {
    # Lualine: Enhanced statusline with clean, minimal design
    # Shows mode, git branch, file path, LSP diagnostics, and cursor position
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
          lualine_a = [ "mode" ];
          lualine_b = [
            "branch"
            "diff"
          ];
          lualine_c = [
            {
              __unkeyed-1 = "filename";
              path = 1; # Show relative path
            }
          ];
          lualine_x = [
            {
              __unkeyed-1 = "diagnostics";
              sources = [ "nvim_lsp" ];
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
          lualine_y = [ "progress" ];
          lualine_z = [ "location" ];
        };
      };
    };

    # Bufferline: Buffer tabs with LSP diagnostics
    # Slant style, integrates with neo-tree offset, shows diagnostic icons
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

    # Notify: Modern notification system
    # Compact fade-in notifications with 3s timeout
    notify = {

      enable = true;
      settings = {
        timeout = 3000;
        top_down = true;
        render = "compact";
        stages = "fade";
      };
    };

    # Trouble: Better diagnostic UI
    # Enhanced quickfix/location list with auto-close
    trouble = {

      enable = true;
      settings = {
        auto_close = true;
        auto_open = false;
        use_diagnostic_signs = true;
      };
    };

    # Alpha: Start screen with modern dashboard layout
    # NIXVIM ASCII art dashboard with quick actions:
    #   f - Find files (Telescope)
    #   r - Recent files (oldfiles)
    #   g - Live grep (text search)
    #   q - Quit Neovim
    # The dashboard uses box-drawing characters for visual structure
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
