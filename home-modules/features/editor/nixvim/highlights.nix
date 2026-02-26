# Custom Highlight Groups
# These override Stylix base16 colors for specific UI elements
# Used to customize indent guides, cursor line, and dashboard styling

{ c, ... }:
{
  programs.nixvim = {
    # Custom highlight groups using native nixvim option
    highlight = {
      # Softer indent guides and scope lines
      IblIndent = {
        fg = c.base01;
        nocombine = true;
      };
      IblScope = {
        fg = c.base02;
        nocombine = true;
      };

      # Make the active window obvious
      CursorLine = {
        bg = c.base01;
      };
      CursorLineNr = {
        fg = c.base0A;
        bold = true;
      };
      LineNr = {
        fg = c.base03;
      };

      # Alpha dashboard styling
      AlphaButtons = {
        fg = c.base05; # Normal text for button content
      };
      AlphaShortcut = {
        fg = c.base0B; # Green for shortcuts
        bold = true;
      };
      AlphaFooter = {
        fg = c.base03; # Muted color for box borders
      };
    };
  };
}
