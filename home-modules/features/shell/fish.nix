# Shell configuration: Fish, atuin, fzf, direnv, zoxide
{
  lib,
  config,
  pkgs,
  repoRoot,
  hostname,
  username,
  ...
}:
let
  cfg = config.features.shell.fish;
  loadSecret = path: envVar: ''
    if test -r ${path}
      set -x ${envVar} (cat ${path})
    end
  '';
in
{
  options.features.shell.fish = {
    enable = lib.mkEnableOption "fish shell with modern tooling";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      fish = {
        enable = true;

        interactiveShellInit = ''
          set -g fish_greeting
          fish_default_key_bindings

          set -gx SUDO_EDITOR nvim
          set -gx EDITOR nvim
          set -gx VISUAL nvim

          set -gx GPG_TTY (tty)
          set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
          set -e SSH_AGENT_PID

          ${loadSecret config.sops.secrets.github_mcp_pat.path "GITHUB_MCP_PAT"}
          ${loadSecret config.sops.secrets.exa_api_key.path "EXA_API_KEY"}
          ${loadSecret config.sops.secrets.context7_api_key.path "CONTEXT7_API_KEY"}

          set -g fzf_fd_opts --hidden --follow --exclude .git
          set -g fzf_preview_dir_cmd 'eza --all --color=always --group-directories-first'
          set -g fzf_preview_file_cmd 'bat --style=numbers --color=always'

          set -g fzf_diff_highlighter 'delta --paging=never --width=120'
          set -g fzf_git_log_format "%C(auto)%h%d %s %C(blue)%cr %C(green)%an"

          set -g fzf_history_time_format "%Y-%m-%d %H:%M"
          set -g fzf_history_opts "--no-sort --exact"

          set -Ux fifc_editor nvim
          fzf_configure_bindings --directory=\ct --git_log=\cg --git_status=\cs --history=\cr --processes=\cp --variables=\cv
        '';

        # Abbreviations use the full repoRoot path (not `.#`) so they resolve
        # from any working directory, not only when cwd is inside the flake.
        shellAbbrs = {
          # System Management
          rebuild = "nh os switch -H ${hostname}";
          hms = "nh home switch -c ${username}@${hostname}";
          diffsys = "nvd diff /run/booted-system /run/current-system";
          sysinfo = "nix run ${repoRoot}#sysinfo";

          # devshell commit function
          cmt = "nix run .#commit";

          # NixOS Development
          qa = "nix --option warn-dirty false run ${repoRoot}#qa";
          gcommit = "nix --option warn-dirty false run ${repoRoot}#commit";
          update = "nix flake update";
          check = "nix flake check --option warn-dirty false";
          fmt = "nix fmt";

          # Devshell Quick Access
          devweb = "nix develop ${repoRoot}#web";
          devrust = "nix develop ${repoRoot}#rust";
          devgo = "nix develop ${repoRoot}#go";
          devagents = "nix develop ${repoRoot}#agents";
          devnix = "nix develop ${repoRoot}#nix-debug";

          # Git Shortcuts
          gs = "git status";
          gd = "git diff";
          gds = "git diff --staged";
          ga = "git add";
          gaa = "git add --all";
          gc = "git commit";
          gca = "git commit --amend";
          gp = "git push";
          gpl = "git pull";
          gco = "git checkout";
          gcb = "git checkout -b";
          gb = "git branch";
          gl = "git log --oneline --graph --decorate -20";
          gla = "git log --oneline --graph --decorate --all -20";
          gst = "git stash";
          gstp = "git stash pop";

          # File Operations
          ll = "eza -lah";
          ls = "eza -hl";
          lt = "eza --tree --level=2";
          lta = "eza --tree --level=3 --all";

          # Common Tools
          lg = "lazygit";
          se = "sudoedit";
          v = "nvim";
          zj = "zellij";

          # Navigation
          nixhome = "cd ${repoRoot}/";
          ".." = "cd ..";
          "..." = "cd ../..";
          "...." = "cd ../../..";
        };

        plugins =
          let
            fp = pkgs.fishPlugins;
          in
          [
            {
              name = "plugin-git";
              inherit (fp.plugin-git) src;
            }
            {
              name = "fzf-fish";
              inherit (fp.fzf-fish) src;
            }
            {
              name = "sponge";
              inherit (fp.sponge) src;
            }
            {
              name = "fifc";
              inherit (fp.fifc) src;
            }
          ];
      };

      atuin = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          auto_sync = true;
          keymap_mode = "vim-insert";
          search_mode = "fuzzy";
          style = "compact";
        };
      };

      fzf = {
        enable = true;
        enableFishIntegration = false;
      };

      direnv = {
        enable = true;
        enableFishIntegration = true;
        nix-direnv.enable = true; # Better Nix flake integration
      };

      zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [
          "--cmd"
          "z"
        ];
      };
    };
  };
}
