_: {
  perSystem =
    { config, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        flakeCheck = true;
      };

      formatter = config.treefmt.build.wrapper;
    };
}
