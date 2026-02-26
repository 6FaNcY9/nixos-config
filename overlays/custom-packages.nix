# Custom package overlays — package overrides and custom builds.
{ inputs }:
final: prev: {
  # tree-sitter-cli: Pinned to 0.26.5 for nixvim treesitter compatibility.
  # Note: Separate from the tree-sitter library that neovim links against.
  # Neovim 0.11.6 requires tree-sitter library 0.25.x (API compatibility),
  # but neovim checkhealth wants tree-sitter CLI 0.26.1+ for parsing features.
  tree-sitter-cli = prev.rustPlatform.buildRustPackage rec {
    pname = "tree-sitter-cli";
    version = "0.26.5";

    src = prev.fetchFromGitHub {
      owner = "tree-sitter";
      repo = "tree-sitter";
      rev = "v${version}";
      hash = "sha256-tnZ8VllRRYPL8UhNmrda7IjKSeFmmOnW/2/VqgJFLgU=";
      fetchSubmodules = true;
    };

    cargoHash = "sha256-EU8kdG2NT3NvrZ1AqvaJPLpDQQwUhYG3Gj5TAjPYRsY=";

    nativeBuildInputs = [ prev.llvmPackages.libclang.lib ];
    buildInputs = [ ];

    # Disable tests (they fail when building just the CLI)
    doCheck = false;

    LIBCLANG_PATH = "${prev.llvmPackages.libclang.lib}/lib";
    BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${prev.llvmPackages.libclang.lib}/lib/clang/${prev.llvmPackages.libclang.version}/include -isystem ${prev.stdenv.cc.libc.dev}/include";

    meta = {
      description = "Tree-sitter CLI tool for parser generation and testing";
      homepage = "https://tree-sitter.github.io/tree-sitter/";
      license = prev.lib.licenses.mit;
    };
  };

  # mistral-vibe: Skip runtime dependency version check for cryptography.
  # Upstream requires cryptography<=46.0.3,>=44.0.0, but nixpkgs has 46.0.4 (compatible patch bump).
  mistral-vibe = prev.mistral-vibe.overridePythonAttrs (_: {
    # Disable runtime dependency version checking entirely
    # The pythonRuntimeDepsCheckHook phase enforces strict version constraints
    dontCheckRuntimeDeps = true;
  });

  # opencode: Force bun isolated installs to prevent symlink issues in nix store.
  # The --linker=isolated flag ensures each package gets its own node_modules copy,
  # preventing "cannot find module" errors with hoisted dependencies.
  # See: https://bun.sh/docs/install/linker
  opencode =
    let
      opencodeSrc = inputs.opencode;
      opencodeRev = opencodeSrc.shortRev or (opencodeSrc.rev or "dirty");
      nodeModules = final.callPackage "${opencodeSrc}/nix/node_modules.nix" {
        rev = opencodeRev;
      };
      nodeModulesPatched = nodeModules.overrideAttrs (old: {
        buildPhase =
          final.lib.replaceStrings [ "bun install \\\n" ] [ "bun install \\\n      --linker=isolated \\\n" ]
            old.buildPhase;
      });
    in
    (final.callPackage "${opencodeSrc}/nix/opencode.nix" {
      node_modules = nodeModulesPatched;
    }).overrideAttrs
      (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace packages/opencode/script/build.ts \
            --replace "../../../node_modules/@opentui/solid/scripts/solid-plugin" \
                      "../node_modules/@opentui/solid/scripts/solid-plugin"
        '';
        # The embedded Bun JS runtime's file watcher needs libstdc++.so.6 at runtime.
        # The upstream installPhase already wraps with makeBinaryWrapper for PATH.
        # We re-wrap to also add LD_LIBRARY_PATH for the native watcher binding.
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/opencode \
            --prefix LD_LIBRARY_PATH : "${final.stdenv.cc.cc.lib}/lib"
        '';
      });
}
