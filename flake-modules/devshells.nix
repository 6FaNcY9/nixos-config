{
  inputs,
  pkgsFor,
  ...
}: {
  perSystem = {
    system,
    config,
    lib,
    ...
  }: let
    pkgs = pkgsFor system;
    cfgLib = import ../lib {inherit lib;};
    common = import ./_common.nix {inherit pkgs lib config inputs cfgLib;};
    inherit (common) commonDevPackages maintenanceDevPackages devshellStartup opencodePkg;
  in {
    devshells = {
      maintenance = {
        packages = maintenanceDevPackages;
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Maintenance Shell";
            description = ''
              Type ',' to see all available commands
              Quick actions: fmt, qa, update, clean, sysinfo

              Bash users: source $MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/,
            '';
          };
          startup = devshellStartup;
        };
      };

      default = {
        packages = maintenanceDevPackages;
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Development Shell";
            description = ''
              Type ',' to see all available commands
              Services: nix run .#services (postgres, redis)
              Quick shells: devweb, devrust, devgo, devflask

              Bash users: source $MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/,
            '';
          };
          startup = devshellStartup;
        };
      };

      flask = {
        packages =
          commonDevPackages
          ++ (with pkgs; [
            python3
            python3Packages.flask
            python3Packages.requests
            python3Packages.virtualenv
            python3Packages.pip
            poetry
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Flask Development Shell";
          emoji = "🐍";
          description = "Python: ${pkgs.python3.version}";
        };
      };

      web = {
        packages =
          commonDevPackages
          ++ (with pkgs; [
            nodejs # Includes npm by default
            pnpm # Standalone, no nodejs conflict
            yarn # Standalone, no nodejs conflict
            nodePackages.typescript
            nodePackages.typescript-language-server
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Web Development Shell";
          emoji = "🌐";
          description = ''
            Node: ${pkgs.nodejs.version}
            npm, pnpm, yarn, TypeScript available
          '';
        };
      };

      agents = {
        packages =
          commonDevPackages
          ++ [
            opencodePkg
          ]
          ++ (with pkgs; [
            nodejs
            pnpm
            bun
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Agent Tools Shell";
          emoji = "🤖";
          description = ''
            opencode + vercel CLI
            oh-my-opencode: bunx oh-my-opencode install
            agent-browser: npx @vercel/agent-browser
            If Playwright browsers missing: npx playwright install
          '';
        };
      };

      rust = {
        packages =
          commonDevPackages
          ++ (with pkgs; [
            rustc
            cargo
            rustfmt
            clippy
            rust-analyzer
            cargo-watch
            cargo-edit
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Rust Development Shell";
          emoji = "🦀";
          description = "Rustc: ${pkgs.rustc.version}";
        };
      };

      go = {
        packages =
          commonDevPackages
          ++ (with pkgs; [
            go
            gopls # Go language server
            delve # Go debugger
            go-tools # staticcheck, etc.
            gotools # goimports, etc.
            gomodifytags
            impl
            gotests
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Go Development Shell";
          emoji = "🐹";
          description = ''
            Go: ${pkgs.go.version}
            gopls, delve, staticcheck available
          '';
        };
      };

      pentest = {
        packages =
          commonDevPackages
          ++ (with pkgs; [
            nmap
            wireshark
            tcpdump
            netcat
            socat
            sqlmap
            john
            hashcat
            metasploit
            burpsuite
            nikto
            dirb
            gobuster
            ffuf
            hydra
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Penetration Testing Shell";
          emoji = "🔐";
          description = ''
            Security testing tools available
            nmap, wireshark, metasploit, burpsuite, etc.
          '';
        };
      };

      database = {
        packages =
          commonDevPackages
          ++ (with pkgs; [
            # Database servers
            postgresql
            mysql80
            sqlite
            redis
            mongodb-tools
            pgcli
            mycli
            litecli
            mongosh
            dbeaver-bin
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Database Development Shell";
          emoji = "🗄️";
          description = ''
            Database clients and tools available
            PostgreSQL, MySQL 8.0, SQLite, Redis, MongoDB
          '';
        };
      };

      nix-debug = {
        packages =
          commonDevPackages
          ++ (with pkgs; [
            # Interactive Nix tools
            nix-tree # Visual dependency tree explorer (nix-tree /run/current-system)
            nix-diff # Compare derivations (nix-diff drv1.drv drv2.drv)
            nix-output-monitor # Better build output (nom build ...)
            nix-eval-jobs # Parallel evaluation
            # Documentation and exploration
            manix # Search Nix documentation (manix <term>)
            nurl # Generate Nix fetcher calls from URLs
            nix-prefetch-git # Prefetch git repositories
            nix-prefetch-github # Prefetch GitHub repositories
            # Analysis tools
            nixpkgs-review # Review nixpkgs PRs
            nixfmt
            nixd # Nix language server
          ]);
        devshell.motd = cfgLib.mkDevshellMotd {
          title = "Nix Debugging & Analysis Shell";
          emoji = "🔍";
          description = ''
            Interactive Nix exploration and debugging tools:
            • nix repl         - Interactive Nix REPL (:lf . to load flake)
            • nix-tree         - Visual dependency explorer
            • nix-diff         - Compare derivations
            • nom              - Better build output (nom build ...)
            • manix            - Search Nix documentation
            • nurl             - Generate fetcher calls from URLs
            • nixpkgs-review   - Review nixpkgs PRs

            Try: nix repl → :lf . → outputs.nixosConfigurations
          '';
        };
      };
    };
  };
}
