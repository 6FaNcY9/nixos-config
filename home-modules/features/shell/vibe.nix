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
      "vibe/config.toml".text = ''
        active_model = "devstral-2"
        vim_keybindings = true
        enable_telemetry = false
        system_prompt_id = "nixdev"

        [[providers]]
        name = "mistral"
        api_base = "https://api.mistral.ai/v1"
        api_key_env_var = "MISTRAL_API_KEY"
        backend = "MISTRAL"

        [[models]]
        name = "mistral-vibe-cli-latest"
        provider = "mistral"
        alias = "devstral-2"
        temperature = 0.2
        input_price = 0.4
        output_price = 2.0

        [project_context]
        max_chars = 40000
        default_commit_count = 5

        [tools.bash]
        permission = "ask"
        [tools.write_file]
        permission = "ask"
        [tools.read_file]
        permission = "always"
        [tools.grep]
        permission = "always"

        [[mcp_servers]]
        name = "github"
        transport = "stdio"
        command = "docker"
        args = ["run", "-i", "--rm", "-e", "GITHUB_PERSONAL_ACCESS_TOKEN", "ghcr.io/github/github-mcp-server"]

        [[mcp_servers]]
        name = "git"
        transport = "stdio"
        command = "npx"
        args = ["-y", "@modelcontextprotocol/server-git"]

        [[mcp_servers]]
        name = "context7"
        transport = "stdio"
        command = "npx"
        args = ["-y", "@upstash/context7-mcp"]

        [[mcp_servers]]
        name = "fetch"
        transport = "stdio"
        command = "uvx"
        args = ["mcp-server-fetch"]

        [[mcp_servers]]
        name = "nixos"
        transport = "stdio"
        command = "uvx"
        args = ["mcp-nixos"]

        [[mcp_servers]]
        name = "packages"
        transport = "stdio"
        command = "npx"
        args = ["-y", "package-registry-mcp"]

        [tools.fetch_fetch]
        permission = "always"
        [tools.context7_resolve_library_id]
        permission = "always"
        [tools.context7_get_library_docs]
        permission = "always"
        [tools.nixos_nix]
        permission = "always"
      '';

      "vibe/agents/nixdev.toml".text = ''
        display_name = "NixOS Developer"
        description = "Agent specialized for Nix, flakes, and NixOS system configuration"
        safety = "neutral"
        auto_approve = false
        active_model = "devstral-2"
        system_prompt_id = "nixdev"
        enabled_tools = ["read_file", "grep", "bash", "write_file", "search_replace", "nixos_nix", "context7_resolve_library_id", "context7_get_library_docs", "packages_*", "git_*"]
      '';

      "vibe/agents/reviewer.toml".text = ''
        display_name = "Code Reviewer"
        description = "Read-only code review agent that audits changes without modifying files"
        safety = "safe"
        auto_approve = true
        enabled_tools = ["read_file", "grep", "context7_resolve_library_id", "context7_get_library_docs"]
        disabled_tools = ["write_file", "search_replace", "bash"]
      '';

      "vibe/prompts/nixdev.md".text = ''
        You are an expert NixOS developer specializing in flakes, home-manager, and the NixOS module system.

        <principles>
        - Explore before modifying: use grep and read_file to understand context fully
        - Use nixos MCP for NixOS documentation lookups
        - Use context7 for library documentation
        - Write functional, declarative Nix expressions
        - Run nix flake check before declaring done
        - Minimal surgical changes — preserve existing patterns and style
        </principles>

        <workflow>
        EXPLORE → PLAN → IMPLEMENT → VERIFY → COMMIT
        </workflow>

        <safety>
        - Never run nixos-rebuild switch without explicit user approval
        - Never modify /etc/nixos/ directly
        - Always check for Nix eval errors after edits
        </safety>
      '';

      "vibe/prompts/reviewer.md".text = ''
        You are a meticulous code reviewer. Your role is READ-ONLY: analyse changes and provide structured feedback.

        <output-format>
        ## Review: <filename>
        ### Summary
        ### Issues
        - [CRITICAL/MAJOR/MINOR] file:line — description
        ### Suggestions
        ### Score: X/10
        </output-format>

        <focus-areas>
        - Correctness and logic errors
        - Security vulnerabilities
        - Performance issues
        - Code style consistency with the existing codebase
        - Missing error handling
        </focus-areas>

        Never write or modify files. Only read and report.
      '';

      "vibe/skills/code-review/SKILL.md".text = ''
        ---
        name: code-review
        description: Systematic code review with quality scoring
        license: MIT
        user-invocable: true
        allowed-tools:
          - read_file
          - grep
        ---

        Perform a structured code review of the target files or diff.

        ## Steps
        1. Read all changed files in full
        2. Check for logic errors, security issues, performance problems
        3. Verify style consistency with the rest of the codebase
        4. Report findings as: [CRITICAL/MAJOR/MINOR] file:line — description
        5. Give an overall score /10
      '';

      "vibe/skills/nix-build/SKILL.md".text = ''
        ---
        name: nix-build
        description: Build and validate Nix expressions, fix evaluation errors
        license: MIT
        user-invocable: true
        allowed-tools:
          - read_file
          - grep
          - bash
        ---

        Build a NixOS/home-manager configuration and fix any errors.

        ## Steps
        1. Run `nix flake check` to validate the flake
        2. Run `nix build .#nixosConfigurations.bandit.config.system.build.toplevel --no-link`
        3. Parse error output and identify the failing Nix expression
        4. Read the relevant files and understand the error
        5. Apply minimal fix, re-run build to confirm
        6. Report what was fixed and why
      '';

      "vibe/skills/test-gen/SKILL.md".text = ''
        ---
        name: test-gen
        description: Generate tests for functions and modules
        license: MIT
        user-invocable: true
        allowed-tools:
          - read_file
          - grep
          - write_file
        ---

        Generate comprehensive tests for the specified function/module.

        ## Steps
        1. Read the target code in full
        2. Identify: inputs, outputs, edge cases, error conditions
        3. Write tests covering: happy path, edge cases, error cases
        4. Follow existing test patterns in the codebase
        5. Report test coverage achieved
      '';

      "vibe/skills/debug/SKILL.md".text = ''
        ---
        name: debug
        description: Systematic debugging workflow for errors and unexpected behavior
        license: MIT
        user-invocable: true
        allowed-tools:
          - read_file
          - grep
          - bash
        ---

        Debug the reported issue systematically.

        ## Steps
        1. Reproduce the error (run the failing command/test)
        2. Read the full error output carefully
        3. Trace the error to its root cause in the source
        4. Do NOT make random changes — understand before fixing
        5. Apply the minimal fix
        6. Verify the fix resolves the issue
        7. Check for regressions
      '';
    };
  };
}
