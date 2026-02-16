# Development service infrastructure via process-compose + services-flake.
# Open TUI with: `, services` or `nix run .#dev-services`
# Services start disabled; select a process and press F7 to start it.
# Data stored in ./data/{pg1,redis1}/ (gitignored)
{ inputs, ... }:
{
  perSystem = _: {
    process-compose."dev-services" = {
      imports = [
        inputs.services-flake.processComposeModules.default
      ];

      services.postgres."pg1" = {
        enable = true;
        port = 5432;
        listen_addresses = "127.0.0.1";
        initialDatabases = [
          { name = "devdb"; }
        ];
      };

      services.redis."redis1" = {
        enable = true;
        port = 6379;
        bind = "127.0.0.1";
      };

      # Don't auto-start services; user picks what to run from the TUI (F7).
      settings.processes = {
        "pg1-init".disabled = true;
        "pg1".disabled = true;
        "redis1".disabled = true;
      };
    };

    # Project-local PostgreSQL for web development.
    # Run via: `, db` (starts from ORIGINAL_PWD so data stays in project dir)
    # Data stored in ./data/pg1/ relative to the project directory.
    process-compose."web-db" = {
      imports = [
        inputs.services-flake.processComposeModules.default
      ];

      services.postgres."pg1" = {
        enable = true;
        port = 5432;
        listen_addresses = "127.0.0.1";
        initialDatabases = [
          { name = "devdb"; }
        ];
      };
    };
  };
}
