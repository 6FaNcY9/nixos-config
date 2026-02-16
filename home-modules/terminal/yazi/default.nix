{ palette, ... }:
{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "modified";
        sort_dir_first = true;
        sort_reverse = true;
      };
    };

    theme = {
      manager = {
        cwd = {
          fg = "${palette.accent}";
        };
        hovered = {
          fg = "${palette.bg}";
          bg = "${palette.accent}";
          bold = true;
        };
        preview_hovered = {
          underline = true;
        };
      };

      status = {
        separator_open = "";
        separator_close = "";
        separator_style = {
          fg = "${palette.accent}";
          bg = "${palette.bg}";
        };
        mode_normal = {
          fg = "${palette.bg}";
          bg = "${palette.accent}";
          bold = true;
        };
        mode_select = {
          fg = "${palette.bg}";
          bg = "${palette.warn}";
          bold = true;
        };
        mode_unset = {
          fg = "${palette.bg}";
          bg = "${palette.danger}";
          bold = true;
        };
      };

      filetype = {
        rules = [
          {
            mime = "image/*";
            fg = "${palette.accent2}";
          }
          {
            mime = "video/*";
            fg = "${palette.warn}";
          }
          {
            mime = "audio/*";
            fg = "${palette.danger}";
          }
          {
            name = "*.nix";
            fg = "${palette.accent}";
          }
        ];
      };
    };
  };
}
