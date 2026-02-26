# Nixpkgs overlays — exports the custom-packages overlay.
#
# This overlay provides:
#   - tree-sitter-cli: pinned to 0.26.5 for nixvim compatibility
#   - mistral-vibe: patched to skip cryptography version check
#   - opencode: patched for bun isolated installs + libstdc++ runtime support
{ inputs }:
{
  default = import ./custom-packages.nix { inherit inputs; };
}
