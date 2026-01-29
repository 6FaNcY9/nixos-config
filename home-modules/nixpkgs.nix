_: {
  # Ensure CLI nix commands can evaluate unfree packages too.
  xdg.configFile."nixpkgs/config.nix".text = ''
    {
      allowUnfree = true;
    }
  '';
}
