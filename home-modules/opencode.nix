# OpenCode (Oh-My-OpenCode) configuration
#
# This module configures the OpenCode AI assistant with:
# - Multiple AI providers (Anthropic, OpenAI, Gemini, OpenCode, GitHub Copilot, Antigravity)
# - Agent definitions (Sisyphus, Oracle, Explore, etc.)
# - Model fallback chains for reliability
# - Category-specific model assignments
#
# Structure:
# 1. Provider configurations (antigravityProviderConfig)
# 2. Agent requirements and fallback chains (agentRequirements, categoryRequirements)
# 3. Model chain builders (mkModelChain, mkModel, etc.)
# 4. Configuration options (config.opencode.ohMyOpencode)
# 5. Final configuration assembly
{
  lib,
  config,
  ...
}: let
  cfg = config.opencode.ohMyOpencode;

  schemaUrl = "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/master/assets/oh-my-opencode.schema.json";
  ultimateFallback = "opencode/big-pickle";
  zaiModel = "zai-coding-plan/glm-4.7";

  ohMyPlugin = "oh-my-opencode@${cfg.pluginVersion}";
  antigravityPlugin = "opencode-antigravity-auth";

  antigravityProviderConfig = {
    name = "Google";
    models = {
      "antigravity-gemini-3-pro" = {
        name = "Gemini 3 Pro (Antigravity)";
        limit = {
          context = 1048576;
          output = 65535;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {thinkingLevel = "low";};
          high = {thinkingLevel = "high";};
        };
      };
      "antigravity-gemini-3-flash" = {
        name = "Gemini 3 Flash (Antigravity)";
        limit = {
          context = 1048576;
          output = 65536;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          minimal = {thinkingLevel = "minimal";};
          low = {thinkingLevel = "low";};
          medium = {thinkingLevel = "medium";};
          high = {thinkingLevel = "high";};
        };
      };
      "antigravity-claude-sonnet-4-5" = {
        name = "Claude Sonnet 4.5 (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
      };
      "antigravity-claude-sonnet-4-5-thinking" = {
        name = "Claude Sonnet 4.5 Thinking (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {thinkingConfig = {thinkingBudget = 8192;};};
          max = {thinkingConfig = {thinkingBudget = 32768;};};
        };
      };
      "antigravity-claude-opus-4-5-thinking" = {
        name = "Claude Opus 4.5 Thinking (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {thinkingConfig = {thinkingBudget = 8192;};};
          max = {thinkingConfig = {thinkingBudget = 32768;};};
        };
      };
    };
  };

  agentRequirements = {
    sisyphus = {
      fallbackChain = [
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["zai-coding-plan"];
          model = "glm-4.7";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2-codex";
          variant = "medium";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
        }
      ];
    };
    oracle = {
      fallbackChain = [
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
          variant = "high";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
        }
      ];
    };
    librarian = {
      fallbackChain = [
        {
          providers = ["zai-coding-plan"];
          model = "glm-4.7";
        }
        {
          providers = ["opencode"];
          model = "big-pickle";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-sonnet-4-5";
        }
      ];
    };
    explore = {
      fallbackChain = [
        {
          providers = ["anthropic" "opencode"];
          model = "claude-haiku-4-5";
        }
        {
          providers = ["opencode"];
          model = "gpt-5-nano";
        }
      ];
    };
    "multimodal-looker" = {
      fallbackChain = [
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-flash";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
        }
        {
          providers = ["zai-coding-plan"];
          model = "glm-4.6v";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-haiku-4-5";
        }
        {
          providers = ["opencode"];
          model = "gpt-5-nano";
        }
      ];
    };
    prometheus = {
      fallbackChain = [
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
          variant = "high";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
        }
      ];
    };
    metis = {
      fallbackChain = [
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
          variant = "high";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
          variant = "max";
        }
      ];
    };
    momus = {
      fallbackChain = [
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
          variant = "medium";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
          variant = "max";
        }
      ];
    };
    atlas = {
      fallbackChain = [
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-sonnet-4-5";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
        }
      ];
    };
  };

  categoryRequirements = {
    "visual-engineering" = {
      fallbackChain = [
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
          variant = "high";
        }
      ];
    };
    ultrabrain = {
      fallbackChain = [
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2-codex";
          variant = "xhigh";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
        }
      ];
    };
    artistry = {
      fallbackChain = [
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
          variant = "max";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
        }
      ];
    };
    quick = {
      fallbackChain = [
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-haiku-4-5";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-flash";
        }
        {
          providers = ["opencode"];
          model = "gpt-5-nano";
        }
      ];
    };
    "unspecified-low" = {
      fallbackChain = [
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-sonnet-4-5";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2-codex";
          variant = "medium";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-flash";
        }
      ];
    };
    "unspecified-high" = {
      fallbackChain = [
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-opus-4-5";
          variant = "max";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
          variant = "high";
        }
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-pro";
        }
      ];
    };
    writing = {
      fallbackChain = [
        {
          providers = ["google" "github-copilot" "opencode"];
          model = "gemini-3-flash";
        }
        {
          providers = ["anthropic" "github-copilot" "opencode"];
          model = "claude-sonnet-4-5";
        }
        {
          providers = ["zai-coding-plan"];
          model = "glm-4.7";
        }
        {
          providers = ["openai" "github-copilot" "opencode"];
          model = "gpt-5.2";
        }
      ];
    };
  };

  availability = {
    native = {
      claude = cfg.claude != "no";
      inherit (cfg) openai gemini;
    };
    inherit (cfg) opencodeZen copilot;
    zai = cfg.zaiCodingPlan;
    isMaxPlan = cfg.claude == "max20";
  };

  hasAnyProvider =
    availability.native.claude
    || availability.native.openai
    || availability.native.gemini
    || availability.opencodeZen
    || availability.copilot
    || availability.zai;

  providerAvailable = provider:
    if provider == "anthropic"
    then availability.native.claude
    else if provider == "openai"
    then availability.native.openai
    else if provider == "google"
    then availability.native.gemini
    else if provider == "github-copilot"
    then availability.copilot
    else if provider == "opencode"
    then availability.opencodeZen
    else if provider == "zai-coding-plan"
    then availability.zai
    else false;

  transformModel = provider: model:
    if provider == "github-copilot"
    then
      builtins.replaceStrings
      [
        "claude-opus-4-5"
        "claude-sonnet-4-5"
        "claude-haiku-4-5"
        "claude-sonnet-4"
      ]
      [
        "claude-opus-4.5"
        "claude-sonnet-4.5"
        "claude-haiku-4.5"
        "claude-sonnet-4"
      ]
      model
    else model;

  resolveChain = chain: let
    entry = lib.findFirst (e: lib.any providerAvailable e.providers) null chain;
  in
    if entry == null
    then null
    else let
      provider = lib.findFirst providerAvailable null entry.providers;
    in
      {
        model = "${provider}/${transformModel provider entry.model}";
      }
      // lib.optionalAttrs (entry ? variant) {inherit (entry) variant;};

  mkModel = resolved: defaultVariant: let
    resolvedVariant =
      resolved.variant or (
        if defaultVariant != null
        then defaultVariant
        else null
      );
  in
    {inherit (resolved) model;}
    // lib.optionalAttrs (resolvedVariant != null) {variant = resolvedVariant;};

  sisyphusNonMaxChain = [
    {
      providers = ["anthropic" "github-copilot" "opencode"];
      model = "claude-sonnet-4-5";
    }
    {
      providers = ["openai" "github-copilot" "opencode"];
      model = "gpt-5.2";
      variant = "high";
    }
    {
      providers = ["google" "github-copilot" "opencode"];
      model = "gemini-3-pro";
    }
  ];

  buildAgent = role: req:
    if !hasAnyProvider
    then {model = ultimateFallback;}
    else if role == "librarian" && availability.zai
    then {model = zaiModel;}
    else if role == "explore"
    then
      if availability.native.claude
      then {model = "anthropic/claude-haiku-4-5";}
      else if availability.opencodeZen
      then {model = "opencode/claude-haiku-4-5";}
      else {model = "opencode/gpt-5-nano";}
    else let
      chain =
        if role == "sisyphus" && !availability.isMaxPlan
        then sisyphusNonMaxChain
        else req.fallbackChain;
      resolved = resolveChain chain;
    in
      if resolved == null
      then {model = ultimateFallback;}
      else mkModel resolved (req.variant or null);

  buildCategory = name: req:
    if !hasAnyProvider
    then {model = ultimateFallback;}
    else let
      chain =
        if name == "unspecified-high" && !availability.isMaxPlan
        then categoryRequirements."unspecified-low".fallbackChain
        else req.fallbackChain;
      resolved = resolveChain chain;
    in
      if resolved == null
      then {model = ultimateFallback;}
      else mkModel resolved (req.variant or null);

  agents = lib.genAttrs (builtins.attrNames agentRequirements) (role: buildAgent role agentRequirements.${role});
  categories = lib.genAttrs (builtins.attrNames categoryRequirements) (name: buildCategory name categoryRequirements.${name});

  opencodeConfig =
    {
      plugin =
        [ohMyPlugin]
        ++ lib.optionals cfg.gemini [antigravityPlugin];
    }
    // lib.optionalAttrs cfg.gemini {
      provider = {
        google = antigravityProviderConfig;
      };
    };

  omoConfig = {
    "$schema" = schemaUrl;
    inherit agents categories;
  };
in {
  options.opencode.ohMyOpencode = {
    enable = lib.mkEnableOption "oh-my-opencode plugin for OpenCode";

    pluginVersion = lib.mkOption {
      type = lib.types.str;
      default = "3.0.1";
      description = "oh-my-opencode npm tag or version to pin in opencode.json.";
    };

    claude = lib.mkOption {
      type = lib.types.enum ["no" "yes" "max20"];
      default = "no";
      description = "Claude subscription tier (no, yes, or max20).";
    };

    openai = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable OpenAI/ChatGPT provider models.";
    };

    gemini = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Gemini provider models (adds Antigravity auth plugin + provider config).";
    };

    copilot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable GitHub Copilot fallback provider models.";
    };

    opencodeZen = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable OpenCode Zen opencode/ model access.";
    };

    zaiCodingPlan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Z.ai Coding Plan models.";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."opencode/opencode.json".text = builtins.toJSON opencodeConfig + "\n";
    xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON omoConfig + "\n";
  };
}
