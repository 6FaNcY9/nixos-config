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
          "gfx.font_rendering.fontconfig.max_generic_substitutions" = 127;
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
          "browser.compactmode.show" = true;
          "browser.uidensity" = 1;
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
      };
    };
  };
}
