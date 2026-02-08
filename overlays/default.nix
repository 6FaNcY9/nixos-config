{inputs}: {
  default = final: prev: {
    # Stable packages available as pkgs.stable.* (fallback when unstable breaks)
    stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };

    # OpenCode override: force bun isolated installs
    # Required because bun's default hoisting behavior breaks symlinks in the nix store.
    # The --linker=isolated flag ensures each package gets its own node_modules copy,
    # preventing the "cannot find module" errors that occur with hoisted dependencies.
    # See: https://bun.sh/docs/install/linker
    opencode = let
      opencodeSrc = inputs.opencode;
      opencodeRev = opencodeSrc.shortRev or (opencodeSrc.rev or "dirty");
      nodeModules = final.callPackage "${opencodeSrc}/nix/node_modules.nix" {
        rev = opencodeRev;
      };
      nodeModulesPatched = nodeModules.overrideAttrs (old: {
        buildPhase =
          final.lib.replaceStrings
          ["bun install \\\n"]
          ["bun install \\\n      --linker=isolated \\\n"]
          old.buildPhase;
      });
    in
      (final.callPackage "${opencodeSrc}/nix/opencode.nix" {
        node_modules = nodeModulesPatched;
      })
      .overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace packages/opencode/script/build.ts \
              --replace "../../../node_modules/@opentui/solid/scripts/solid-plugin" \
                        "../node_modules/@opentui/solid/scripts/solid-plugin"
          '';
      });
  };
}
