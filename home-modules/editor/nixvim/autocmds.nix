_: {
  programs.nixvim = {
    # Auto-groups for organizing related autocmds
    autoGroups = {
      highlight_cursorline = {
        clear = true;
      };
    };

    # Autocmds using native nixvim option
    autoCmd = [
      # Make the active window obvious (enable cursorline on active window)
      {
        event = [
          "WinEnter"
          "BufEnter"
        ];
        group = "highlight_cursorline";
        callback.__raw = ''
          function()
            vim.wo.cursorline = true
          end
        '';
      }
      {
        event = [ "WinLeave" ];
        group = "highlight_cursorline";
        callback.__raw = ''
          function()
            vim.wo.cursorline = false
          end
        '';
      }
    ];
  };
}
