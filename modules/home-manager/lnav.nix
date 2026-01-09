{
  pkgs,
  c,
  ...
}: {
  home.packages = [pkgs.lnav];

  xdg.configFile."lnav/configs/nix/theme.json".text = builtins.toJSON {
    "$schema" = "https://lnav.org/schemas/config-v1.schema.json";
    ui = {
      theme = "vino";
      "theme-defs" = {
        vino = {
          vars = {
            bg = c.base00;
            bg_alt = c.base01;
            fg = c.base05;
            accent = c.base0D;
            warn = c.base0A;
            error = c.base08;
            muted = c.base03;
          };

          styles = {
            text = {
              color = "$fg";
              "background-color" = "$bg";
            };
            "selected-text" = {
              color = "$bg";
              "background-color" = "$accent";
            };
            "cursor-line" = {"background-color" = "$bg_alt";};
            warning = {
              color = "$warn";
              "background-color" = "$bg";
              bold = true;
            };
            error = {
              color = "$error";
              "background-color" = "$bg";
              bold = true;
            };
          };

          "status-styles" = {
            title = {
              color = "$bg";
              "background-color" = "$accent";
              bold = true;
            };
            text = {
              color = "$fg";
              "background-color" = "$bg_alt";
            };
            warn = {
              color = "$warn";
              "background-color" = "$bg_alt";
              bold = true;
            };
            alert = {
              color = "$error";
              "background-color" = "$bg_alt";
              bold = true;
            };
          };

          "log-level-styles" = {
            info = {color = "$accent";};
            warning = {
              color = "$warn";
              bold = true;
            };
            error = {
              color = "$error";
              bold = true;
            };
            critical = {
              color = "$error";
              "background-color" = "$bg_alt";
              bold = true;
            };
            debug = {color = "$muted";};
          };
        };
      };
    };
  };
}
