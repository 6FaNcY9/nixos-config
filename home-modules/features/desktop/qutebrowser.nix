# Qutebrowser web browser configuration
# Keyboard-driven browser managed by Home Manager and themed via Stylix.
{
  lib,
  pkgs,
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
    home.activation.qutebrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dictDir="$HOME/.local/share/qutebrowser/qtwebengine_dictionaries"
      if [ ! -f "$dictDir/en-US-8-0.bdic" ]; then
        $DRY_RUN_CMD ${pkgs.qutebrowser}/share/qutebrowser/scripts/dictcli.py install en-US de-DE || true
      fi
    '';

    programs.qutebrowser = {
      enable = true;

      settings = {
        # --- Dark mode ---
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

        # --- Tab bar ---
        # Active tab: bgAlt bg + orange text to match system accent
        # Inactive tabs: primary bg + muted text so they recede
        "colors.tabs.bar.bg" = c.base00;
        "colors.tabs.even.bg" = c.base00;
        "colors.tabs.odd.bg" = c.base00;
        "colors.tabs.even.fg" = c.base03;
        "colors.tabs.odd.fg" = c.base03;
        "colors.tabs.selected.even.bg" = c.base01;
        "colors.tabs.selected.odd.bg" = c.base01;
        "colors.tabs.selected.even.fg" = c.base09;
        "colors.tabs.selected.odd.fg" = c.base09;
        "colors.tabs.indicator.start" = c.base0D;
        "colors.tabs.indicator.stop" = c.base0B;
        "colors.tabs.indicator.error" = c.base08;

        # --- Status bar modes ---
        # Each mode gets a distinct text color; bg stays dark across all modes.
        # Normal: green | Insert: teal | Command: yellow | Private: pink
        "colors.statusbar.normal.bg" = c.base00;
        "colors.statusbar.normal.fg" = c.base0B;
        "colors.statusbar.insert.bg" = c.base00;
        "colors.statusbar.insert.fg" = c.base0D;
        "colors.statusbar.command.bg" = c.base00;
        "colors.statusbar.command.fg" = c.base0A;
        "colors.statusbar.command.private.bg" = c.base00;
        "colors.statusbar.command.private.fg" = c.base0E;
        "colors.statusbar.private.bg" = c.base01;
        "colors.statusbar.private.fg" = c.base0E;
        "colors.statusbar.progress.bg" = c.base0B;

        # --- Ad blocking ---
        "content.blocking.method" = "both"; # block via both hosts file and ad
        "content.blocking.adblock.lists" = [
          "https://easylist.to/easylist/easylist.txt"
          "https://easylist.to/easylist/easyprivacy.txt"
          "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt"
          "https://secure.fanboy.co.nz/fanboy-cookielist.txt"
          "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
        ];

        # --- User agent: Chrome on Linux (qutebrowser UA triggers Cloudflare bot detection) ---
        "content.headers.user_agent" =
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36";

        # --- Privacy ---
        "content.cookies.accept" = "no-3rdparty"; # block 3rd
        "content.canvas_reading" = false; # block canvas fingerprinting
        "content.geolocation" = false; # block geolocation API
        "content.notifications.enabled" = false; # block notifications API
        "content.webrtc_ip_handling_policy" = "disable-non-proxied-udp"; # limit WebRTC IP leaks

        # --- UX ---
        "scrolling.smooth" = true; # smooth scrolling
        "downloads.location.directory" = "~/Downloads"; # default download dir
        "downloads.location.prompt" = false; # don't prompt for download location
        "tabs.last_close" = "close"; # close window when last tab is closed
        "auto_save.session" = true; # auto-save session
        "content.pdfjs" = true; # use built-in PDF viewer

        # --- Spellchecking ---
        "spellcheck.languages" = [
          "en-US"
          "de-DE" # de-AT not available; de-DE covers Austrian German
        ];
      };

      searchEngines = {
        DEFAULT = "https://duckduckgo.com/?q={}";
        d = "https://duckduckgo.com/?q={}";
        g = "https://www.google.com/search?hl=en&q={}";
        nw = "https://wiki.nixos.org/index.php?search={}";
        w = "https://en.wikipedia.org/wiki/Special:Search?search={}";
        yt = "https://www.youtube.com/results?search_query={}";
        gh = "https://github.com/search?q={}";
        np = "https://search.nixos.org/packages?query={}";
        no = "https://search.nixos.org/options?query={}";
        cr = "https://crates.io/search?q={}";
        rd = "https://docs.rs/{}";
      };
      keyBindings.normal = {
        # --- Open current URL in external browser
        ",f" = "spawn firefox {url}"; # open in Firefox when Cloudflare blocks

        # Translate current page to English via Google Translate (auto-detect source language)
        ",t" = "open https://translate.google.com/translate?sl=auto&tl=en&u={url}";
        "x" = "tab-close";
        "X" = "undo";
        "J" = "tab-prev";
        "K" = "tab-next";
        "gp" = "tab-pin";
      };
      extraConfig = ''
        # --- Cloudflare Turnstile: allow canvas, cookies, WebGL for challenge iframe ---
        # QtWebEngine lacks navigator.userAgentData (QTBUG-107260) so Turnstile may still
        # fail on some sites regardless — open in Firefox as fallback if needed.
        config.set('content.canvas_reading', True, 'https://challenges.cloudflare.com')
        config.set('content.cookies.accept', 'all', 'https://challenges.cloudflare.com')
        config.set('content.webgl', True, 'https://challenges.cloudflare.com')

        # --- Don't invert Cloudflare challenge pages (dark mode breaks the widget) ---
        config.set('colors.webpage.darkmode.enabled', False, 'https://challenges.cloudflare.com')

        # --- mail.mrija.org: allow all cookies (site requires session cookies to log in) ---
        config.set('content.cookies.accept', 'all', 'https://mail.mrija.org')

        # --- claude.ai: allow canvas reading (required for file upload UI) ---
        config.set('content.canvas_reading', True, 'https://claude.ai')
      '';
    };
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = [ desktopFile ];
      "x-scheme-handler/https" = [ desktopFile ];
      "text/html" = [ desktopFile ];
    };
  };
}
