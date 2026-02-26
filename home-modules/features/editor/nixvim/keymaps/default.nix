# Keymaps Entry Point
# Organizes all keybindings by category for clarity
#
# Categories:
#   telescope.nix    - Fuzzy finder shortcuts (ff, fg, fb, fh, fk, fc)
#   editor.nix       - Editor tools (Tutor, Cheatsheet, Neotree, Format, Markview)
#   copilot.nix      - AI completion controls (M-l, M-w, M-j, M-[, M-])
#   navigation.nix   - Buffer navigation (Tab/S-Tab cycle, bd, bp)
#   terminal.nix     - ToggleTerm float
#   lsp.nix          - Trouble diagnostics integration

_: {
  imports = [
    ./telescope.nix
    ./editor.nix
    ./copilot.nix
    ./navigation.nix
    ./terminal.nix
    ./lsp.nix
  ];
}
