{...}: {
  perSystem = {
    config,
    ...
  }: {
    mission-control = {
      scripts = {
        fmt = {
          description = "Format Nix files";
          exec = config.treefmt.build.wrapper;
          category = "Dev Tools";
        };
        qa = {
          description = "Format, lint, and flake check";
          exec = "nix run .#qa";
          category = "Dev Tools";
        };
        update = {
          description = "Update flake inputs";
          exec = "nix run .#update";
          category = "Dev Tools";
        };
        clean = {
          description = "Remove result symlinks";
          exec = "nix run .#clean";
          category = "Dev Tools";
        };
        sysinfo = {
          description = "System diagnostics and status";
          exec = "nix run .#sysinfo";
          category = "Analysis";
        };
        tree = {
          description = "Visualize nix dependencies";
          exec = "nix-tree";
          category = "Analysis";
        };
        web = {
          description = "Enter web development shell";
          exec = "nix develop .#web";
          category = "Dev Shells";
        };
        rust = {
          description = "Enter Rust development shell";
          exec = "nix develop .#rust";
          category = "Dev Shells";
        };
        go = {
          description = "Enter Go development shell";
          exec = "nix develop .#go";
          category = "Dev Shells";
        };
        flask = {
          description = "Enter Flask development shell";
          exec = "nix develop .#flask";
          category = "Dev Shells";
        };
        agents = {
          description = "Enter Agent Tools shell";
          exec = "nix develop .#agents";
          category = "Dev Shells";
        };
        database = {
          description = "Enter Database development shell";
          exec = "nix develop .#database";
          category = "Dev Shells";
        };
      };
    };
  };
}
