# Library functions for nixos-config.
#
# Provides helper functions for workspaces, validation, devshells, colors, options, and polybar.

{ lib }:
let
  # mkWorkspaceName :: { number :: Int, icon :: Str } -> Str
  # Format workspace as "number:icon" (or just "number" if icon is empty).
  mkWorkspaceName =
    ws:
    let
      number = toString ws.number;
      icon = ws.icon or "";
    in
    if icon == "" then number else "${number}:${icon}";

  # validateSecretExists :: Path -> Bool
  # Assert that a secret file exists at the given path. Throws if missing.
  validateSecretExists =
    secretPath:
    assert builtins.pathExists secretPath || throw "Secret file not found: ${toString secretPath}";
    true;

  # validateSecretEncrypted :: Path -> Bool
  # Assert that a secret file is encrypted by sops (checks for sops metadata). Throws if unencrypted.
  # Requires BOTH the encrypted payload marker AND the sops metadata header so that a file
  # containing "ENC[AES256_GCM" in a comment but no real encryption still fails.
  validateSecretEncrypted =
    secretPath:
    let
      exists = builtins.pathExists secretPath;
      content = if exists then builtins.readFile secretPath else "";
      hasPayload = lib.hasInfix "ENC[AES256_GCM" content;
      hasSopsMeta = lib.hasInfix "sops:" content;
      isEncrypted = exists && hasPayload && hasSopsMeta;
    in
    assert
      isEncrypted
      || throw ''
        Validation failed: Secret file appears to be unencrypted
          File: ${secretPath}
          Hint: Use 'sops -e ${secretPath}' to encrypt it
      '';
    true;

  # mkSecretValidation :: { secrets :: [Path], label :: Str? } -> { valid :: Bool, assertions :: [Assertion] }
  # Validate a list of secret files: all must exist and be encrypted.
  # Returns a structure suitable for NixOS assertions.
  mkSecretValidation =
    {
      secrets,
      label ? "secrets",
    }:
    let
      missing = builtins.filter (p: !(builtins.pathExists p)) secrets;
      valid = builtins.all (path: (validateSecretExists path) && (validateSecretEncrypted path)) secrets;
    in
    {
      inherit valid;
      assertions = [
        {
          assertion = valid;
          message =
            "${label}: one or more secret files are missing or unencrypted."
            + lib.optionalString (
              missing != [ ]
            ) " Missing: ${lib.concatStringsSep ", " (map toString missing)}";
        }
      ];
    };

  # mkPolybarTwoTone :: { icon :: Str, color :: Str, colorAlt :: Str?, fg :: Str? } -> AttrSet
  # Two-tone polybar module style: icon block (dark color) + label block (bright variant).
  mkPolybarTwoTone =
    {
      icon,
      color,
      colorAlt ? "${color}-alt",
      fg ? "black",
    }:
    {
      format-prefix = "  ${icon} ";
      format-prefix-foreground = "\${colors.${fg}}";
      format-prefix-background = "\${colors.${color}}";
      label-foreground = "\${colors.${fg}}";
      label-background = "\${colors.${colorAlt}}";
      label-padding-left = 1;
      label-padding-right = 1;
    };

  # mkPolybarTwoToneState :: { state :: Str, icon :: Str, color :: Str, colorAlt :: Str?, fg :: Str? } -> AttrSet
  # Two-tone style for a named state (e.g. format-volume, format-charging).
  mkPolybarTwoToneState =
    {
      state,
      icon,
      color,
      colorAlt ? "${color}-alt",
      fg ? "black",
    }:
    {
      "format-${state}-prefix" = "  ${icon} ";
      "format-${state}-prefix-foreground" = "\${colors.${fg}}";
      "format-${state}-prefix-background" = "\${colors.${color}}";
      "format-${state}" = "<label-${state}>";
      "label-${state}-foreground" = "\${colors.${fg}}";
      "label-${state}-background" = "\${colors.${colorAlt}}";
      "label-${state}-padding-left" = 1;
      "label-${state}-padding-right" = 1;
    };

  # mkBtrfsOpts :: Str -> [Str]
  # Generate BTRFS mount options optimized for SSD + battery life.
  # Subvolume, noatime, nodiratime, zstd:1 compression, space_cache=v2, async TRIM.
  mkBtrfsOpts = subvol: [
    "subvol=${subvol}"
    "noatime"
    "nodiratime"
    "compress-force=zstd:1" # force-compress all files; zstd:1 is fast + better than heuristic skip
    "space_cache=v2"
    "discard=async"
  ];

in
{
  # Workspace helpers
  inherit mkWorkspaceName;

  # mkWorkspaceBindings :: { mod :: Str, workspaces :: [Workspace], commandPrefix :: Str, shift :: Bool? } -> AttrSet
  # Generate i3 keybindings for workspace switching/moving.
  mkWorkspaceBindings =
    {
      mod,
      workspaces,
      commandPrefix,
      shift ? false,
    }:
    let
      keyPrefix = if shift then "${mod}+Shift+" else "${mod}+";
    in
    builtins.listToAttrs (
      map (ws: {
        # i3 uses key "0" for workspace 10 (single-char key after modifier)
        name = "${keyPrefix}${if ws.number == 10 then "0" else toString ws.number}";
        value = "${commandPrefix} \"${mkWorkspaceName ws}\"";
      }) workspaces
    );

  # Validation helpers
  inherit
    validateSecretExists
    validateSecretEncrypted
    mkSecretValidation
    ;

  # Polybar helpers
  inherit mkPolybarTwoTone mkPolybarTwoToneState;

  # Filesystem helpers
  inherit mkBtrfsOpts;
}
