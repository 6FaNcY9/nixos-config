# Nixpkgs overlays — custom package overrides and builds.
#
# Exports:
#   - opencode-bun: Bun runtime wrapper for opencode-ai@latest (impure, fetches on first run)
#   - mistral-vibe: Official flake package (uv2nix Python wrapper)
#   - tree-sitter-cli: Pinned to 0.26.5 for nixvim compatibility
#   - hermes-agent: Nous Research self-improving AI agent (upstream flake)
{ inputs }:
{
  default = import ./custom-packages.nix { inherit inputs; };
}
