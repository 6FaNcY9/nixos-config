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
          meta.description = "Update the system and all packages.";
        };

        clean = {
          type = "app";
          program = "${config.packages.clean}/bin/clean";
          meta.description = "Clean up the system by removing old generations and unused packages.";
        };

        qa = {
          type = "app";
          program = "${config.packages.qa}/bin/qa";
          meta.description = "Run quality assurance checks on the system.";
        };

        commit = {
          type = "app";
          program = "${config.packages.commit-tool}/bin/commit";
          meta.description = "A tool to help create well-formatted commit messages.";
        };

        generate-age-key = {
          type = "app";
          program = "${config.packages.generate-age-key}/bin/generate-age-key";
          meta.description = "Generate a new age key pair for encryption.";
        };

        sysinfo = {
          type = "app";
          program = "${config.packages.sysinfo}/bin/sysinfo";
          meta.description = "Display system information and diagnostics.";
        };

        cachix-push = {
          type = "app";
          program = "${config.packages.cachix-push}/bin/cachix-push";
          meta.description = "Push build results to Cachix cache.";
        };
      };
    };
}
