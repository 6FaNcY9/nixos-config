# Flake apps — run with `nix run .#<name>` from outside devshells.
# For in-shell equivalents, use `just <recipe>` (see justfile).
#
# Apps reference packages (packages.nix) to avoid duplication.
# Each app is self-contained with its own runtime dependencies.
{
  perSystem =
    { config, ... }:
    {
      apps = {
        # Update flake inputs
        update = {
          type = "app";
          program = "${config.packages.update}/bin/update";
          meta.description = "Update the system and all packages.";
        };

        # Clean build artifacts and result symlinks
        clean = {
          type = "app";
          program = "${config.packages.clean}/bin/clean";
          meta.description = "Clean up the system by removing old generations and unused packages.";
        };

        # Run quality assurance (format, lint, checks)
        qa = {
          type = "app";
          program = "${config.packages.qa}/bin/qa";
          meta.description = "Run quality assurance checks on the system.";
        };

        # Interactive commit helper with QA checks
        commit = {
          type = "app";
          program = "${config.packages.commit-tool}/bin/commit";
          meta.description = "A tool to help create well-formatted commit messages.";
        };

        # Generate age encryption key pair for sops-nix
        generate-age-key = {
          type = "app";
          program = "${config.packages.generate-age-key}/bin/generate-age-key";
          meta.description = "Generate a new age key pair for encryption.";
        };

        # System information and diagnostics
        sysinfo = {
          type = "app";
          program = "${config.packages.sysinfo}/bin/sysinfo";
          meta.description = "Display system information and diagnostics.";
        };

        # Push build results to Cachix binary cache
        cachix-push = {
          type = "app";
          program = "${config.packages.cachix-push}/bin/cachix-push";
          meta.description = "Push build results to Cachix cache.";
        };
      };
    };
}
