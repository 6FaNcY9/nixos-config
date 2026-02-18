# Development service infrastructure via process-compose + services-flake.
# Open TUI with: `, services` or `nix run .#dev-services`
# Services start disabled; select a process and press F7 to start it.
# Data stored in ./data/{pg1,redis1}/ (gitignored)
{ inputs, ... }:
{
  perSystem =
    _:
    let
      # Shared PostgreSQL configuration template
      # Used by both dev-services and web-db
      pg1 = {
        enable = true;
        port = 5432;
        listen_addresses = "127.0.0.1"; # Localhost only for security
        initialDatabases = [ { name = "devdb"; } ];
      };
    in
    {
      # Multi-service development environment (PostgreSQL + Redis)
      # ────────────────────────────────────────────────────────────
      # Usage:
      #   Start TUI:    nix run .#dev-services (or `, services`)
      #   Start service: Select process, press F7
      #   Stop service:  Select process, press F9
      #   Exit:         Ctrl+C or q
      #
      # Services:
      #   PostgreSQL:
      #     - Connection: localhost:5432
      #     - Database:   devdb
      #     - User:       postgres (no password)
      #     - Data:       ./data/pg1/
      #     - CLI:        psql -h localhost -U postgres devdb
      #
      #   Redis:
      #     - Connection: localhost:6379
      #     - Data:       ./data/redis1/
      #     - CLI:        redis-cli -h localhost
      process-compose."dev-services" = {
        imports = [
          inputs.services-flake.processComposeModules.default
        ];

        # PostgreSQL database for local development
        # Connection details in header comment above
        services.postgres."pg1" = pg1;

        # Redis cache/queue for local development
        # Binds to localhost only for security
        services.redis."redis1" = {
          enable = true;
          port = 6379;
          bind = "127.0.0.1";
        };

        # Don't auto-start services; user picks what to run from the TUI (F7).
        # This prevents unnecessary resource usage when you only need one service.
        settings.processes = {
          "pg1-init".disabled = true;
          "pg1".disabled = true;
          "redis1".disabled = true;
        };
      };

      # Dedicated PostgreSQL for web projects
      # ──────────────────────────────────────
      # Usage:
      #   Start:  nix run .#web-db (or `, db`)
      #   Stop:   Ctrl+C
      #
      # Connection:
      #   Host:     localhost
      #   Port:     5432
      #   Database: devdb
      #   User:     postgres (no password)
      #   CLI:      psql -h localhost -U postgres devdb
      #
      # Data persistence:
      #   - Stored in ./data/pg1/ relative to project directory
      #   - Preserved between runs (gitignored)
      #   - Starts from ORIGINAL_PWD so data location is predictable
      process-compose."web-db" = {
        imports = [
          inputs.services-flake.processComposeModules.default
        ];

        # Uses same PostgreSQL config as dev-services
        # Auto-starts on launch (no TUI interaction needed)
        services.postgres."pg1" = pg1;
      };
    };
}
