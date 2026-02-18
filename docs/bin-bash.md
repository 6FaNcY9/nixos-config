Why /bin/bash isn't present on NixOS
=================================

On traditional Linux distributions /bin contains essential userland binaries and many third-party scripts assume common interpreters live under `/bin` (for example `#!/bin/bash`). NixOS uses an immutable, declarative package management model and places packages under the Nix store (`/nix/store/...`) rather than installing them to global `/bin` paths. As a result, a plain `/bin/bash` symlink is not provided by default; shells are available through package paths (e.g. `${pkgs.bash}/bin/bash`) and via the `environment.shells` configuration.

Why a symlink sometimes appears in this repo
--------------------------------------------

This repository creates a small activation-script symlink that points `/bin/bash` to the Nix store path for `bash`. See `nixos-modules/core.nix` where `system.activationScripts.binbash` creates the symlink during activation. The purpose is compatibility: many third-party scripts (or vendor binaries) hardcode `#!/bin/bash` and cannot easily be changed.

Prefer alternatives where possible
---------------------------------

Before falling back to providing `/bin/bash`, prefer these safer alternatives:

- Use `pkgs.writeShellScript` in Nix expressions to wrap scripts with the correct interpreter at build time.
- Use an explicit shebang that references the Nix package: `#!${pkgs.bash}/bin/bash` inside Nix-built scripts. This produces reproducible, hermetic scripts that reference the exact bash binary from the store.

When the symlink hack is justified
---------------------------------

The `/bin/bash` symlink is a pragmatic compatibility hack and should be used only when:

1. You're running 3rd-party scripts or vendor plugins that cannot be edited and that require `#!/bin/bash`.
2. You're in constrained environments (like some CI runners or closed-source utilities) where patching the shebang isn't feasible.
3. For developer convenience in local/OpenCode workflows where changing upstream code is impractical.

When you control the code, prefer the alternatives above. The symlink reduces purity and may hide hard-to-debug dependency issues by providing an implicit global binary.

Notes and links
---------------

- Activation script creating `/bin/bash` is located at `nixos-modules/core.nix` (see `system.activationScripts.binbash`).
- If you can change the script, prefer `#!${pkgs.bash}/bin/bash` or `pkgs.writeShellScript`.

If you land here from README.md or comments in `nixos-modules/core.nix`, follow the alternatives listed above before adding global symlinks.
