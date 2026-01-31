{...}: {
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      cursorline = true;
      cursorlineopt = "number,line";
      relativenumber = true;
      number = true;

      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      smartindent = true;

      wrap = false;
      ignorecase = true;
      smartcase = true;

      hlsearch = false;
      incsearch = true;
      termguicolors = true;

      scrolloff = 8;
      signcolumn = "no";

      laststatus = 3;
      colorcolumn = "100";

      updatetime = 200;
      undofile = true;
      swapfile = false;
    };
  };
}
