# Feature: System Monitoring
# Provides: Prometheus + Grafana monitoring stack
# Dependencies: None (optional standalone service)
{
  config,
  lib,
  ...
}:
let
  cfg = config.features.services.monitoring;
in
{
  options.features.services.monitoring = {
    enable = lib.mkEnableOption "system monitoring with Prometheus and exporters";

    grafana = {
      enable = lib.mkEnableOption "Grafana dashboards";

      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Grafana web interface port";
      };

      domain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Domain for Grafana (null = localhost only)";
      };
    };

    prometheus = {
      port = lib.mkOption {
        type = lib.types.port;
        default = 9090;
        description = "Prometheus web interface port";
      };

      retentionTime = lib.mkOption {
        type = lib.types.str;
        default = "15d";
        description = "How long to keep metrics data";
      };
    };

    exporters = {
      node = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable node_exporter for system metrics";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 9100;
          description = "Node exporter port";
        };
      };
    };

    logging = {
      enhancedJournal = lib.mkEnableOption "enhanced systemd journal logging configuration";

      maxRetentionDays = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Maximum journal log retention in days";
      };

      maxSize = lib.mkOption {
        type = lib.types.str;
        default = "500M";
        description = "Maximum size for journal logs";
      };
    };
  };

  config = lib.mkMerge [
    # Warning: Monitoring is resource-intensive
    (lib.mkIf (cfg.enable && cfg.grafana.enable) {
      warnings = [
        "Grafana is enabled - expect 5-8% battery drain and ~344MB RAM usage on laptop"
      ];
    })

    # Prometheus configuration
    (lib.mkIf cfg.enable {
      services.prometheus = {
        enable = true;
        inherit (cfg.prometheus) port retentionTime;

        exporters = lib.mkIf cfg.exporters.node.enable {
          node = {
            enable = true;
            inherit (cfg.exporters.node) port;
            enabledCollectors = [
              "cpu"
              "diskstats"
              "filesystem"
              "loadavg"
              "meminfo"
              "netdev"
              "stat"
              "time"
              "uname"
              "systemd"
            ];
          };
        };

        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [
              {
                targets = [ "localhost:${toString cfg.exporters.node.port}" ];
              }
            ];
          }
        ];
      };

      # Open firewall for Prometheus (localhost only by default)
      networking.firewall.interfaces.lo.allowedTCPPorts = [ cfg.prometheus.port ];
    })

    # Grafana configuration
    (lib.mkIf (cfg.enable && cfg.grafana.enable) {
      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "127.0.0.1";
            http_port = cfg.grafana.port;
            domain = if cfg.grafana.domain != null then cfg.grafana.domain else "localhost";
          };

          analytics = {
            reporting_enabled = false;
            check_for_updates = false;
          };
        };

        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://localhost:${toString cfg.prometheus.port}";
              isDefault = true;
            }
          ];
        };
      };

      # Open firewall for Grafana (localhost only by default)
      networking.firewall.interfaces.lo.allowedTCPPorts = [ cfg.grafana.port ];
    })

    # Enhanced journal logging
    (lib.mkIf cfg.logging.enhancedJournal {
      services.journald.extraConfig = ''
        # Retention settings
        MaxRetentionSec=${toString (cfg.logging.maxRetentionDays * 86400)}
        SystemMaxUse=${cfg.logging.maxSize}
        SystemKeepFree=1G

        # Enable persistent storage
        Storage=persistent

        # Compress old logs
        Compress=yes

        # Forward to syslog for additional processing if needed
        ForwardToSyslog=no

        # Rate limiting (prevent log spam)
        RateLimitIntervalSec=30s
        RateLimitBurst=10000
      '';

      # Create journal directory
      systemd.tmpfiles.rules = [ "d /var/log/journal 0755 root root -" ];
    })
  ];
}
