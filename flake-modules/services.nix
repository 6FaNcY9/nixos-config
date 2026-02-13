# Development service infrastructure via process-compose + services-flake.
# Start with: `, services` or `nix run .#dev-services`
# Data stored in ./data/{pg1,redis1}/ (gitignored)
{inputs, ...}: {
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
          {name = "devdb";}
        ];
      };

      services.redis."redis1" = {
        enable = true;
        port = 6379;
        bind = "127.0.0.1";
      };
    };
  };
}
