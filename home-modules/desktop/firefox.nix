{
  lib,
  pkgs,
  username,
  c,
  config,
  cfgLib,
  ...
}:
{
  config = lib.mkIf config.profiles.desktop {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox;

      # Enforce privacy-related policies (enterprise policies)
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisableFirefoxAccounts = true;
        DisablePocket = true; # deprecated but still hides UI
        DNSOverHTTPS = {
          Enabled = false;
        };
        FirefoxHome = {
          SponsoredTopSites = false;
          SponsoredPocket = false;
        };
        FirefoxSuggest = {
          SponsoredSuggestions = false;
          ImproveSuggest = false;
        };
      };

      profiles.${username} = {
        id = 0;
        isDefault = lib.mkDefault true;

        settings = {
          # ════════════════════════════════════════════════════════════
          # APPEARANCE - Dark mode
          # ════════════════════════════════════════════════════════════
          "ui.systemUsesDarkTheme" = 1;
          "layout.css.prefers-color-scheme.content-override" = 0; # 0 = dark
          "browser.theme.dark-private-windows" = true;
          "browser.theme.toolbar-theme" = 0; # 0 = dark
          "browser.display.use_system_colors" = false;

          # Enable custom CSS
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          # UI density
          "browser.compactmode.show" = true;
          "browser.uidensity" = 1; # compact

          # Font rendering
          "gfx.font_rendering.fontconfig.max_generic_substitutions" = 127;

          # ════════════════════════════════════════════════════════════
          # PRIVACY - Balanced (doesn't break sites)
          # ════════════════════════════════════════════════════════════

          # Tracking protection
          "privacy.trackingprotection.enabled" = true;
          "privacy.trackingprotection.socialtracking.enabled" = true;
          "privacy.trackingprotection.cryptomining.enabled" = true;
          "privacy.trackingprotection.fingerprinting.enabled" = true;

          # Cookie isolation (strict but doesn't break sites)
          "privacy.firstparty.isolate" = false; # Can break logins
          "network.cookie.cookieBehavior" = 5; # Block cross-site and social trackers

          # Referrer control (balanced)
          "network.http.referer.XOriginPolicy" = 1; # Send only if base domains match
          "network.http.referer.XOriginTrimmingPolicy" = 2; # Send only scheme+host+port

          # Disable telemetry
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.archive.enabled" = false;
          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "browser.ping-centre.telemetry" = false;

          # Disable Pocket
          "extensions.pocket.enabled" = false;
          "extensions.pocket.api" = "";
          "extensions.pocket.site" = "";

          # Disable sponsored content
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;

          # Disable Firefox accounts / sync prompts
          "identity.fxaccounts.enabled" = false;

          # DNS over HTTPS (use system DNS, can enable if needed)
          "network.trr.mode" = 5; # 5 = off, 2 = first, 3 = only

          # Disable prefetching (privacy + saves bandwidth)
          "network.dns.disablePrefetch" = true;
          "network.prefetch-next" = false;
          "network.predictor.enabled" = false;

          # ════════════════════════════════════════════════════════════
          # PERFORMANCE
          # ════════════════════════════════════════════════════════════

          # Hardware acceleration
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true; # VA-API on Linux
          "media.hardware-video-decoding.force-enabled" = true;

          # Memory cache (disable disk cache for SSD longevity)
          "browser.cache.disk.enable" = false;
          "browser.cache.memory.enable" = true;
          "browser.cache.memory.capacity" = 524288; # 512MB

          # Session restore (reduce memory)
          "browser.sessionstore.max_tabs_undo" = 10;
          "browser.sessionstore.max_windows_undo" = 3;

          # Reduce animations
          "ui.prefersReducedMotion" = 0; # 0 = no preference, 1 = reduce

          # ════════════════════════════════════════════════════════════
          # UX IMPROVEMENTS
          # ════════════════════════════════════════════════════════════

          # Tab behavior
          "browser.tabs.tabMinWidth" = 100;
          "browser.tabs.insertAfterCurrent" = true;
          "browser.tabs.closeWindowWithLastTab" = false;
          "toolkit.tabbox.switchByScrolling" = true;

          # URL bar
          "browser.urlbar.suggest.searches" = true;
          "browser.urlbar.suggest.history" = true;
          "browser.urlbar.suggest.bookmark" = true;
          "browser.urlbar.suggest.openpage" = true;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.maxRichResults" = 8;

          # Downloads
          "browser.download.useDownloadDir" = true;
          "browser.download.folderList" = 1; # 0 = Desktop, 1 = Downloads, 2 = custom
          "browser.download.manager.addToRecentDocs" = false;

          # Disable annoyances
          "browser.aboutConfig.showWarning" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.tabs.warnOnClose" = false;
          "browser.tabs.warnOnCloseOtherTabs" = false;
          "general.autoScroll" = true; # Middle-click scroll

          # Reader mode
          "reader.color_scheme" = "dark";
          "reader.content_width" = 5;
        };

        # Search engines
        search = {
          force = true;
          default = "ddg";
          privateDefault = "ddg";
          engines = {
            "google".metaData.hidden = false;
            "bing".metaData.hidden = true;
            "amazondotcom-us".metaData.hidden = true;
            "ebay".metaData.hidden = true;
            "wikipedia".metaData.hidden = false;
          };
        };

        userChrome =
          let
            themeTemplate = builtins.readFile ../../assets/firefox/userChrome.theme.css;
            replaceColors = cfgLib.mkColorReplacer { colors = c; };
          in
          lib.mkAfter (
            (builtins.readFile ../../assets/firefox/userChrome.css) + "\n" + replaceColors themeTemplate
          );

        userContent = builtins.readFile ../../assets/firefox/userContent.css;
      };
    };
  };
}
