{
  lib,
  pkgs,
  username,
  c,
  config,
  ...
}: let
  cfgLib = import ../lib {inherit lib;};
in {
  config = lib.mkIf config.profiles.desktop {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;

      profiles.${username} = {
        id = 0;
        isDefault = lib.mkDefault true;

        settings = {
          # Force dark mode everywhere
          "ui.systemUsesDarkTheme" = 1;
          "layout.css.prefers-color-scheme.content-override" = 0; # 0 = dark, 1 = light
          "browser.theme.dark-private-windows" = true;
          "browser.theme.toolbar-theme" = 0; # 0 = dark, 1 = light, 2 = system

          # Dark mode for content pages
          "browser.display.use_system_colors" = false;
          "browser.display.document_color_use" = 2; # 0 = always, 1 = never, 2 = only with high contrast

          # Font rendering
          "gfx.font_rendering.fontconfig.max_generic_substitutions" = 127;

          # Enable custom CSS
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # UI customization
          "browser.compactmode.show" = true;
          "browser.uidensity" = 1;

          # Privacy/UX
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "toolkit.tabbox.switchByScrolling" = true;
          "browser.tabs.tabMinWidth" = 120;
        };

        userChrome = let
          themeTemplate = builtins.readFile ../assets/firefox/userChrome.theme.css;
          # Use our centralized color replacement helper
          replaceColors = cfgLib.mkColorReplacer {colors = c;};
        in
          lib.mkAfter (
            (builtins.readFile ../assets/firefox/userChrome.css)
            + "\n"
            + replaceColors themeTemplate
          );

        userContent = builtins.readFile ../assets/firefox/userContent.css;
      };
    };
  };
}
