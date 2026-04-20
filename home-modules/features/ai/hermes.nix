# hermes-agent AI assistant configuration (Nous Research)
#
# Secrets management follows upstream docs: API keys go into secrets/hermes.yaml
# as a single `hermes_env` key (multiline .env format). The sops-decrypted file
# is copied to ~/.hermes/.env at activation; hermes reads it via load_hermes_dotenv()
# on every startup. Keys never appear in the Nix store.
#
# config.yaml is seeded once on first install; hermes rewrites it at runtime
# (e.g. `hermes setup`, `hermes model`), so we use activation rather than home.file.
#
# To add/rotate API keys:
#   sops secrets/hermes.yaml
# Add under `hermes_env: |`:
#   OPENROUTER_API_KEY=sk-or-...
#   ANTHROPIC_API_KEY=sk-ant-...  (optional, for direct Anthropic access)
#
{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.features.ai.hermes;
  hermesSecretFile = "${inputs.self}/secrets/hermes.yaml";

  # Config seed: written once on first install. Hermes will modify this at runtime.
  # Use `openrouter/auto` so hermes picks the best available model automatically.
  hermesConfigSeed = pkgs.writeText "hermes-config-seed.yaml" ''
    model:
      default: "openrouter/auto"
      provider: "auto"
    agent:
      max_turns: 60
      reasoning_effort: "medium"
    memory:
      memory_enabled: true
      user_profile_enabled: true
    compression:
      enabled: true
      threshold: 0.50
    terminal:
      backend: "local"
      timeout: 180
    display:
      tool_progress: "all"
      streaming: true
      compact: false
    skills:
      creation_nudge_interval: 15
  '';
in
{
  options.features.ai.hermes = {
    enable = lib.mkEnableOption "hermes-agent AI assistant (Nous Research)";
  };

  config = lib.mkIf cfg.enable {
    home.activation = {
      # Seed config.yaml only on first install.
      # Hermes modifies this file at runtime, so never overwrite an existing one.
      hermesConfigSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        HERMES_DIR="$HOME/.hermes"
        HERMES_CONFIG="$HERMES_DIR/config.yaml"
        if [ ! -f "$HERMES_CONFIG" ]; then
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HERMES_DIR"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp ${hermesConfigSeed} "$HERMES_CONFIG"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 0600 "$HERMES_CONFIG"
          echo "hermes: seeded $HERMES_CONFIG"
        fi
      '';

      # Write ~/.hermes/.env from sops-decrypted hermes_env secret.
      # The secret value is the entire .env file content (KEY=value lines).
      # Hermes reads this via load_hermes_dotenv() on every startup.
      # Only written when secrets/hermes.yaml exists in the repo.
      hermesEnvFile = lib.hm.dag.entryAfter [ "writeBoundary" "sopsNix" ] ''
        ${lib.optionalString (builtins.pathExists hermesSecretFile) ''
          HERMES_DIR="$HOME/.hermes"
          ENV_SRC="${config.sops.secrets.hermes_env.path}"
          if [ -f "$ENV_SRC" ]; then
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HERMES_DIR"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp "$ENV_SRC" "$HERMES_DIR/.env"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 0600 "$HERMES_DIR/.env"
          fi
        ''}
      '';
    };
  };
}
