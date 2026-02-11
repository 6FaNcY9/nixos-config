_: {
  perSystem = {config, ...}: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs.alejandra.enable = true;
      flakeCheck = true;
    };

    formatter = config.treefmt.build.wrapper;
  };
}
