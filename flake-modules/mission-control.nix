{
  primaryHost,
  username,
  ...
}: {
  perSystem = {config, ...}: {
    mission-control = {
      scripts = {
        # ── Dev Tools ────────────────────────────────────────────
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
          exec = "nix flake update";
          category = "Dev Tools";
        };
        clean = {
          description = "Remove result symlinks";
          exec = "rm -f result result-*";
          category = "Dev Tools";
        };

        # ── Analysis ─────────────────────────────────────────────
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

        # ── Git ──────────────────────────────────────────────────
        status = {
          description = "Show short git status";
          exec = "git status -sb";
          category = "Git";
        };
        log = {
          description = "Show recent commit log";
          exec = "git log --oneline --decorate --graph -20";
          category = "Git";
        };
        diff = {
          description = "Show unstaged changes";
          exec = "git diff";
          category = "Git";
        };
        commit = {
          description = "Commit staged changes with a message";
          exec = ''
            echo "Staged changes:"
            git diff --cached --stat
            echo ""
            read -rp "Commit message: " msg
            git commit -m "$msg"
          '';
          category = "Git";
        };
        qa-commit = {
          description = "Full QA pipeline + stage + commit";
          exec = "nix run .#commit";
          category = "Git";
        };

        # ── Build / Deploy ───────────────────────────────────────
        rebuild = {
          description = "Rebuild and switch NixOS (nh)";
          exec = "nh os switch -H ${primaryHost}";
          category = "Build";
        };
        rebuild-test = {
          description = "Test rebuild without switching (nh)";
          exec = "nh os test -H ${primaryHost}";
          category = "Build";
        };
        home-switch = {
          description = "Rebuild and switch Home Manager (nh)";
          exec = "nh home switch -c ${username}@${primaryHost}";
          category = "Build";
        };

        # ── Dev Shells ───────────────────────────────────────────
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
        pentest = {
          description = "Enter Penetration Testing shell";
          exec = "nix develop .#pentest";
          category = "Dev Shells";
        };
        nix-debug = {
          description = "Enter Nix Debugging & Analysis shell";
          exec = "nix develop .#nix-debug";
          category = "Dev Shells";
        };
      };
    };
  };
}
