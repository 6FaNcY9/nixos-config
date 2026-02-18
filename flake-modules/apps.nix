# Apps are for `nix run .#<name>` from outside devshells (standalone, self-contained).
# For in-shell equivalents, use `just <recipe>` (see justfile).
# Apps reference packages (defined in packages.nix) to avoid duplication.
{
  perSystem =
    { config, ... }:
    {
      apps = {
        update = {
          type = "app";
          program = "${config.packages.update}/bin/update";
        };

        clean = {
          type = "app";
          program = "${config.packages.clean}/bin/clean";
        };

        qa = {
          type = "app";
          program = "${config.packages.qa}/bin/qa";
        };

        commit = {
          type = "app";
          program = "${config.packages.commit-tool}/bin/commit";
        };

        generate-age-key = {
          type = "app";
          program = "${config.packages.generate-age-key}/bin/generate-age-key";
        };

        sysinfo = {
          type = "app";
          program = "${config.packages.sysinfo}/bin/sysinfo";
        };

        cachix-push = {
          type = "app";
          program = "${config.packages.cachix-push}/bin/cachix-push";
        };
      };
    };
}
