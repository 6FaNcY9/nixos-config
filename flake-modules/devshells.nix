_: {
  perSystem = {common, ...}: let
    inherit (common) pkgs cfgLib commonDevPackages missionControlPackages flakeToolsPackages devshellStartup opencodePkg;
  in {
    devshells = {
      default = {
        packages = flakeToolsPackages;
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "NixOS Config Shell";
            description = ''
              Type ',' to see all available commands
              Quick actions: fmt, qa, update, clean, sysinfo

              Bash users: source $MISSION_CONTROL_COMPLETIONS/share/bash-completion/completions/,
            '';
          };
          startup = devshellStartup;
        };
      };

      flask = {
        packages =
          commonDevPackages
          ++ missionControlPackages
          ++ (with pkgs; [
            python3
            python3Packages.flask
            python3Packages.requests
            python3Packages.virtualenv
            python3Packages.pip
            poetry
          ]);
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Flask Development Shell";
            emoji = "🐍";
            description = ''
              Python: ${pkgs.python3.version}
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };

      web = {
        packages =
          commonDevPackages
          ++ missionControlPackages
          ++ (with pkgs; [
            nodejs
            pnpm
            yarn
            nodePackages.typescript
            nodePackages.typescript-language-server
            bun
            postgresql
          ]);
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Web Development Shell";
            emoji = "🌐";
            description = ''
              Node: ${pkgs.nodejs.version}
              npm, pnpm, yarn, TypeScript available
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };

      agents = {
        packages =
          commonDevPackages
          ++ missionControlPackages
          ++ [
            opencodePkg
          ]
          ++ (with pkgs; [
            nodejs
            pnpm
            bun
          ]);
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Agent Tools Shell";
            emoji = "🤖";
            description = ''
              opencode + vercel CLI
              oh-my-opencode: bunx oh-my-opencode install
              agent-browser: npx @vercel/agent-browser
              If Playwright browsers missing: npx playwright install
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };

      rust = {
        packages =
          commonDevPackages
          ++ missionControlPackages
          ++ (with pkgs; [
            rustc
            cargo
            rustfmt
            clippy
            rust-analyzer
            cargo-watch
            cargo-edit
          ]);
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Rust Development Shell";
            emoji = "🦀";
            description = ''
              Rustc: ${pkgs.rustc.version}
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };

      go = {
        packages =
          commonDevPackages
          ++ missionControlPackages
          ++ (with pkgs; [
            go
            gopls
            delve
            go-tools
            gotools
            gomodifytags
            impl
            gotests
          ]);
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Go Development Shell";
            emoji = "🐹";
            description = ''
              Go: ${pkgs.go.version}
              gopls, delve, staticcheck available
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };

      pentest = {
        packages =
          commonDevPackages
          ++ missionControlPackages
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
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Penetration Testing Shell";
            emoji = "🔐";
            description = ''
              Security testing tools available
              nmap, wireshark, metasploit, burpsuite, etc.
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };

      database = {
        packages =
          commonDevPackages
          ++ missionControlPackages
          ++ (with pkgs; [
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
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Database Development Shell";
            emoji = "🗄️";
            description = ''
              Database clients and tools available
              PostgreSQL, MySQL 8.0, SQLite, Redis, MongoDB
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };

      nix-debug = {
        packages =
          commonDevPackages
          ++ missionControlPackages
          ++ (with pkgs; [
            nix-tree
            nix-diff
            nix-output-monitor
            nix-eval-jobs
            manix
            nurl
            nix-prefetch-git
            nix-prefetch-github
            nixpkgs-review
            nixfmt
            nixd
          ]);
        devshell = {
          motd = cfgLib.mkDevshellMotd {
            title = "Nix Debugging & Analysis Shell";
            emoji = "🔍";
            description = ''
              Interactive Nix exploration and debugging tools:
              nix-tree, nix-diff, nom, manix, nurl, nixpkgs-review
              Try: nix repl > :lf . > outputs.nixosConfigurations
              Type ',' for commands
            '';
          };
          startup = devshellStartup;
        };
      };
    };
  };
}
