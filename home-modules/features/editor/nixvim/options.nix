# Vim Options Configuration
# Core editor behavior, appearance, and usability settings

_: {
  programs.nixvim = {
    # Leader keys for custom keybindings (mapleader=Space, maplocalleader=comma)
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    # Visual feedback and line numbers
    opts = {
      cursorline = true;
      cursorlineopt = "number,line";
      relativenumber = true;
      number = true;

      # Tab settings: 2-space indents, expand tabs to spaces
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      smartindent = true;

      # Search behavior: case-smart search, no persistent highlighting
      wrap = false;
      ignorecase = true;
      smartcase = true;

      # Visual context and column guides
      hlsearch = false;
      incsearch = true;
      termguicolors = true;

      scrolloff = 8; # Keep 8 lines visible above/below cursor for context
      signcolumn = "no"; # No sign column (git/diagnostics use number column tint instead)

      # Status line and visual guides
      laststatus = 3; # Global statusline (single line across all splits)
      colorcolumn = "100"; # Visual guide at 100 characters for line length

      # Performance and history settings
      updatetime = 200; # Faster CursorHold events (for LSP, git signs, etc.)
      undofile = true; # Persistent undo history across sessions
      swapfile = false; # Disable swap files (modern editors don't need them)

      # Completion menu behavior
      completeopt = [
        "menu"
        "menuone"
        "noselect"
      ];
    };
  };
}
