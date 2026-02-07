# Shell configuration: Fish, atuin, fzf, direnv, zoxide
{
  pkgs,
  config,
  repoRoot,
  hostname,
  username,
  ...
}: {
  programs = {
    fish = {
      enable = true;

      shellInit = "";

      interactiveShellInit = ''
        set -g fish_greeting
        fish_default_key_bindings

        set -gx SUDO_EDITOR nvim
        set -gx EDITOR nvim
        set -gx VISUAL nvim

        set -gx GPG_TTY (tty)
        set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
        set -e SSH_AGENT_PID

        if test -d $HOME/.cache/.bun/bin
          set -gx PATH $HOME/.cache/.bun/bin $PATH
        end

        if test -r ${config.sops.secrets.github_mcp_pat.path}
          set -x GITHUB_MCP_PAT (cat ${config.sops.secrets.github_mcp_pat.path})
        end

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

      shellAbbrs = {
        rebuild = "nh os switch -H ${hostname}";
        hms = "nh home switch -c ${username}@${hostname}";

        qa = "nix --option warn-dirty false run ${repoRoot}#qa";
        gcommit = "nix --option warn-dirty false run ${repoRoot}#commit";
        diffsys = "nvd diff /run/booted-system /run/current-system";

        ll = "eza -lah";
        ls = "eza -hl";

        lg = "lazygit";

        se = "sudoedit";

        v = "nvim";
        zj = "zellij";

        nixhome = "cd ${repoRoot}/";
      };

      plugins = with pkgs.fishPlugins; [
        {
          name = "plugin-git";
          inherit (plugin-git) src;
        }
        {
          name = "fzf-fish";
          inherit (fzf-fish) src;
        }
        {
          name = "sponge";
          inherit (sponge) src;
        }
        {
          name = "fifc";
          inherit (fifc) src;
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
      options = ["--cmd" "z"];
    };
  };
}
