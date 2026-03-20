# Qutebrowser web browser configuration
# Keyboard-driven browser managed by Home Manager and themed via Stylix.
{
  lib,
  config,
  c,
  ...
}:
let
  cfg = config.features.desktop.qutebrowser;
  desktopFile = "org.qutebrowser.qutebrowser.desktop";
in
{
  options.features.desktop.qutebrowser = {
    enable = lib.mkEnableOption "qutebrowser web browser";
  };

  config = lib.mkIf cfg.enable {
    programs.qutebrowser = {
      enable = true;

      settings = {
        "colors.webpage.darkmode.enabled" = true;
        "colors.webpage.darkmode.algorithm" = "lightness-cielab"; # least destructive dark mode algorithm
        "colors.webpage.darkmode.policy.page" = "smart"; # only darken actually-light pages
        "colors.webpage.darkmode.policy.images" = "never"; # keep images unaltered

        # --- Completion popup selected item ---
        # Stylix uses base03 (muted gray) → low contrast with match.fg (base0B).
        # Fix: base02 (dark bg tier) keeps match highlights readable (~4.7:1 contrast).
        "colors.completion.item.selected.bg" = c.base02;
        "colors.completion.item.selected.border.top" = c.base02;
        "colors.completion.item.selected.border.bottom" = c.base02;

        # --- Context menu selected item ---
        "colors.contextmenu.selected.bg" = c.base02;
        "colors.contextmenu.selected.fg" = c.base05;

        # --- Caret / visual selection mode ---
        # Stylix uses base03 for caret mode bg; fix to base0D (teal) consistent with active tab.
        "colors.statusbar.caret.bg" = c.base0D;
        "colors.statusbar.caret.fg" = c.base00;
        "colors.statusbar.caret.selection.bg" = c.base0D;
        "colors.statusbar.caret.selection.fg" = c.base00;
      };

      searchEngines = {
        DEFAULT = "https://duckduckgo.com/?q={}";
        d = "https://duckduckgo.com/?q={}";
        g = "https://www.google.com/search?hl=en&q={}";
        nw = "https://wiki.nixos.org/index.php?search={}";
        w = "https://en.wikipedia.org/wiki/Special:Search?search={}";
      };
      keyBindings.normal = {
        # Translate current page to English via Google Translate (auto-detect source language)
        ",t" = "open https://translate.google.com/translate?sl=auto&tl=en&u={url}";
      };
    };
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = [ desktopFile ];
      "x-scheme-handler/https" = [ desktopFile ];
      "text/html" = [ desktopFile ];
    };
  };
}
