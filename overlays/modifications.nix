# Overlay: modifications — overrides of packages that already exist in nixpkgs.
#
# Includes:
#   - tree-sitter-cli: Pinned to 0.26.5 for nixvim treesitter compatibility
_inputs: _final: prev: {
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
}
