_: {
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<cr>";
      options = {
        silent = true;
        desc = "Find files";
      };
    }
    {
      mode = "n";
      key = "<leader>fg";
      action = "<cmd>Telescope live_grep<cr>";
      options = {
        silent = true;
        desc = "Live grep";
      };
    }
    {
      mode = "n";
      key = "<leader>fb";
      action = "<cmd>Telescope buffers<cr>";
      options = {
        silent = true;
        desc = "Buffers";
      };
    }
    {
      mode = "n";
      key = "<leader>fh";
      action = "<cmd>Telescope help_tags<cr>";
      options = {
        silent = true;
        desc = "Help tags";
      };
    }
    {
      mode = "n";
      key = "<leader>fk";
      action = ''
        <cmd> lua require("telescope.builtin").keymaps(
          require("telescope.themes").get_dropdown({
            winblend = 10,
            previewer = false,
            layout_config = { width = 0.80, height = 0.70},
          })
        )<cr>
      '';
      options = {
        silent = true;
        desc = "Keymaps";
      };
    }
    {
      mode = "n";
      key = "<leader>fc";
      action = "<cmd>Telescope commands<cr>";
      options = {
        silent = true;
        desc = "Commands";
      };
    }
  ];
}
