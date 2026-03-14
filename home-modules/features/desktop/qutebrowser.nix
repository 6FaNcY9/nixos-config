# Qutebrowser web browser configuration
# Keyboard-driven browser managed by Home Manager and themed via Stylix.
{
  lib,
  config,
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
