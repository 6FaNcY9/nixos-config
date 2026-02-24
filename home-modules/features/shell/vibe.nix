# Mistral Vibe coding agent
# Provides: vibe CLI, ~/.config/vibe/ config, MCP servers, agents, prompts, skills
# Secret: sops.secrets.mistral_api_key → MISTRAL_API_KEY env var via fish
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.features.shell.vibe;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.features.shell.vibe = {
    enable = mkEnableOption "mistral vibe coding agent";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.mistral-vibe ];

    home.sessionVariables = {
      VIBE_HOME = "${config.xdg.configHome}/vibe";
    };

    programs.fish.interactiveShellInit = ''
      if test -r ${config.sops.secrets.mistral_api_key.path}
        set -x MISTRAL_API_KEY (cat ${config.sops.secrets.mistral_api_key.path})
      end
    '';

    xdg.configFile = {
      "vibe/config.toml".source = ./vibe/config.toml;
      "vibe/agents/nixdev.toml".source = ./vibe/agents/nixdev.toml;
      "vibe/agents/reviewer.toml".source = ./vibe/agents/reviewer.toml;
      "vibe/prompts/nixdev.md".source = ./vibe/prompts/nixdev.md;
      "vibe/prompts/reviewer.md".source = ./vibe/prompts/reviewer.md;
      "vibe/skills/code-review/SKILL.md".source = ./vibe/skills/code-review/SKILL.md;
      "vibe/skills/nix-build/SKILL.md".source = ./vibe/skills/nix-build/SKILL.md;
      "vibe/skills/test-gen/SKILL.md".source = ./vibe/skills/test-gen/SKILL.md;
      "vibe/skills/debug/SKILL.md".source = ./vibe/skills/debug/SKILL.md;
    };
  };
}
