# Qutebrowser web browser configuration
# Keyboard-driven browser managed by Home Manager and themed via Stylix.
#
# Color overrides: Stylix maps base03 (#8a8a8a, the muted comments color) to all
# selected/active states, which produces near-zero contrast. These overrides fix that
# using proper gruvbox-dark-pale semantic roles:
#   - base0D (#83adad teal)  → active tab / caret mode bg  (gruvbox selection accent)
#   - base02 (#4e4e4e)       → completion / contextmenu selection bg (dark-theme subtle)
#   - base01/02              → inactive tab backgrounds (distinguishable from bar)
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

        # --- Tab colors ---
        # Stylix maps base00 to odd tab bg (= bar bg), making them invisible.
        # Fix: use base01/base02 for inactive tabs so they're visible against the bar.
        "colors.tabs.odd.bg" = c.base01;
        "colors.tabs.even.bg" = c.base02;
        # Active tab: base0D (gruvbox teal) with dark fg for clear selection.
        "colors.tabs.selected.odd.bg" = c.base0D;
        "colors.tabs.selected.odd.fg" = c.base00;
        "colors.tabs.selected.even.bg" = c.base0D;
        "colors.tabs.selected.even.fg" = c.base00;
        "colors.tabs.pinned.selected.odd.bg" = c.base0D;
        "colors.tabs.pinned.selected.odd.fg" = c.base00;
        "colors.tabs.pinned.selected.even.bg" = c.base0D;
        "colors.tabs.pinned.selected.even.fg" = c.base00;

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
    };

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = [ desktopFile ];
      "x-scheme-handler/https" = [ desktopFile ];
      "text/html" = [ desktopFile ];
    };
  };
}
