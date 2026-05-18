# Overlay: additions — packages not present in nixpkgs upstream.
#
# Includes:
#   - hermes-agent: Nous Research self-improving AI agent (upstream flake)
#   - mistral-vibe: Official flake package (uv2nix Python venv wrapper)
#   - opencode-bun: Bun runtime wrapper for opencode-ai@latest (impure, fetches on first run)
{ inputs }:
final: prev: {
  # hermes-agent: Nous Research self-improving AI agent.
  # Pulled directly from upstream flake package output (x86_64-linux default).
  hermes-agent = inputs.hermes-agent.packages.${final.stdenv.hostPlatform.system}.default;

  # mistral-vibe: Official flake package (uv2nix Python venv wrapper).
  mistral-vibe = inputs.mistral-vibe.packages.${final.stdenv.hostPlatform.system}.default;

  # opencode-bun: Bun global-install wrapper for latest opencode-ai from npm.
  # IMPURE: installs opencode-ai@latest into $BUN_INSTALL/bin at runtime.
  # Use this alongside pkgs.opencode when you need the very latest upstream release
  # without waiting for a Nix package bump.
  # Respects BUN_INSTALL from home-modules/core/package-managers.nix (XDG-compliant).
  "opencode-bun" = prev.writeShellApplication {
    name = "opencode-bun";
    runtimeInputs = [ prev.bun ];
    text = ''
      BUN_BIN="''${BUN_INSTALL:-$HOME/.bun}/bin"
      if [ ! -x "$BUN_BIN/opencode" ]; then
        echo "opencode-bun: installing opencode-ai@latest via bun..." >&2
        bun install -g opencode-ai@latest
      fi
      exec "$BUN_BIN/opencode" "$@"
    '';
  };
}
