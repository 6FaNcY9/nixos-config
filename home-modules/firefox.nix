{
  lib,
  pkgs,
  username,
  c,
  config,
  ...
}: {
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
          replaceColors =
            builtins.replaceStrings
            ["@@base00@@" "@@base01@@" "@@base02@@" "@@base03@@" "@@base04@@" "@@base05@@" "@@base08@@" "@@base0A@@" "@@base0B@@" "@@base0D@@"]
            [c.base00 c.base01 c.base02 c.base03 c.base04 c.base05 c.base08 c.base0A c.base0B c.base0D];
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
