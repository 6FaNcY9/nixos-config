# Custom package overlays — package overrides and custom builds.
{ inputs }:
final: prev: {
  # tree-sitter-cli: Pinned to 0.26.5 for nixvim treesitter compatibility.
  # Note: Separate from the tree-sitter library that neovim links against.
  # Neovim 0.11.6 requires tree-sitter library 0.25.x (API compatibility),
  # but neovim checkhealth wants tree-sitter CLI 0.26.1+ for parsing features.
  tree-sitter-cli =
    let
      version = "0.26.5";
    in
    prev.rustPlatform.buildRustPackage {
      pname = "tree-sitter-cli";
      inherit version;

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
        mainProgram = "tree-sitter";
      };
    };

  # mistral-vibe: Official flake package (uv2nix Python venv wrapper).
  # Source: inputs.mistral-vibe.packages.${system}.default
  # Exposed in home-modules via mistralVibePkg, but also available as pkgs.mistral-vibe.
  mistral-vibe = inputs.mistral-vibe.packages.${final.stdenv.hostPlatform.system}.default;

  # strip-json-comments-cli: CLI tool to strip JSON comments (used by some dev tools).
  # Upstream has no package-lock.json; we vendor a generated one in overlays/npm-locks/.
  strip-json-comments-cli =
    let
      version = "3.0.0";
    in
    prev.buildNpmPackage {
      pname = "strip-json-comments-cli";
      inherit version;
      src = prev.fetchFromGitHub {
        owner = "sindresorhus";
        repo = "strip-json-comments-cli";
        rev = "v${version}";
        hash = "sha256-aMp/1/TpEed6eHU7FCXMjAkX/2EcOyhR1cPDHek4Noc=";
      };
      npmDepsHash = "sha256-XVUiaKWGX6ucnSq4G2puSjKLZukIpHscaMoVSiKvXtA=";
      dontNpmBuild = true;
      dontNpmPrune = true;
      # Upstream ships no package-lock.json; inject our vendored one.
      postPatch = ''
        cp ${./npm-locks/strip-json-comments-cli-3.0.0-lock.json} ./package-lock.json
      '';
      meta.mainProgram = "strip-json-comments";
    };

  # agentsys: AI agent orchestration CLI (used with Claude).
  # Upstream has no package-lock.json; we vendor a generated one in overlays/npm-locks/.
  agentsys =
    let
      version = "5.1.0";
    in
    prev.buildNpmPackage {
      pname = "agentsys";
      inherit version;
      src = prev.fetchFromGitHub {
        owner = "avifenesh";
        repo = "agentsys";
        rev = "v${version}";
        hash = "sha256-Ms58KSlCa1zee4yUQzXqwEmdYLjV+wYPy0Dg4jXEwB8=";
      };
      npmDepsHash = "sha256-Au15dCG96Ond/y7XisnuN9nKo/5COsdJ4feBW8fe7z0=";
      dontNpmBuild = true;
      dontNpmPrune = true;
      # Upstream ships no package-lock.json; inject our vendored one.
      postPatch = ''
        cp ${./npm-locks/agentsys-5.1.0-lock.json} ./package-lock.json
      '';
      meta.mainProgram = "agentsys";
    };

  # opencode: Force bun isolated installs to prevent symlink issues in nix store.
  # The --linker=isolated flag ensures each package gets its own node_modules copy,
  # preventing "cannot find module" errors with hoisted dependencies.
  # See: https://bun.sh/docs/install/linker
  opencode =
    let
      opencodeSrc = inputs.opencode;
      opencodeRev = opencodeSrc.shortRev or (opencodeSrc.rev or "dirty");
      # opencode 1.2.15+ requires bun ≥1.3.10; fall back to pinned build only if nixpkgs is older.
      bun_1_3_10 =
        if prev.lib.versionAtLeast prev.bun.version "1.3.10" then
          prev.bun
        else
          prev.bun.overrideAttrs (_: {
            version = "1.3.10";
            src = prev.fetchurl {
              url = "https://github.com/oven-sh/bun/releases/download/bun-v1.3.10/bun-linux-x64.zip";
              hash = "sha256-9XvAGH45Yj3nFro6OJ/aVIay175xMamAulTce3M9Lgg=";
            };
          });
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
      bun = bun_1_3_10;
    }).overrideAttrs
      (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace packages/opencode/script/build.ts \
            --replace "../../../node_modules/@opentui/solid/scripts/solid-plugin" \
                      "../node_modules/@opentui/solid/scripts/solid-plugin"
          # packages/script/src/index.ts reads .github/TEAM_MEMBERS at module init.
          # The nix source fileset excludes .github/, so we create an empty stub.
          mkdir -p .github
          touch .github/TEAM_MEMBERS
          # Restore serverUrl in plugin input so plugins like oh-my-opencode work.
          # Upstream replaced it with a throwing getter in 1.2.21+; we patch it to
          # return the hardcoded default URL (port 4096, matching createOpencodeClient).
          # This matches the pending fix in oh-my-openagent PR #2419.
          # sed -z treats the file as one record (null-delimited), enabling \n in patterns.
          sed -z -i \
            's/get serverUrl(): URL {\n        throw new Error("Server URL is no longer supported in plugins")\n      },/serverUrl: new URL("http:\/\/localhost:4096"),/' \
            packages/opencode/src/plugin/index.ts
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
