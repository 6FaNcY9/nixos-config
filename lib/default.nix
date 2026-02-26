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
  validateSecretEncrypted =
    secretPath:
    let
      exists = builtins.pathExists secretPath;
      content = if exists then builtins.readFile secretPath else "";
      # Check if file is SOPS-encrypted (AES256-GCM marker present)
      isEncrypted = exists && (lib.hasInfix "ENC[AES256_GCM" content);
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

  # mkDevshellMotd :: { title :: Str, emoji :: Str?, description :: Str? } -> Str
  # Create a formatted MOTD (message of the day) for devshells with color codes.
  mkDevshellMotd =
    {
      title,
      emoji ? "🔨",
      description ? "",
    }:
    ''
      {202}${emoji} ${title}{reset}
      ${description}
    '';

  # mkShellScript :: { pkgs :: Pkgs, name :: Str, body :: Str } -> Derivation
  # Create a shell script with standard error handling (set -euo pipefail).
  # Note: For scripts with runtime dependencies, use pkgs.writeShellApplication instead.
  mkShellScript =
    {
      pkgs,
      name,
      body,
    }:
    pkgs.writeShellScriptBin name ''
      set -euo pipefail
      ${body}
    '';

  # darkenColor :: Float -> Str -> Str
  # Darken a #rrggbb hex color by a fraction (0.0 - 1.0).
  # Example: darkenColor 0.30 "#ff8700" => "#b25e00"
  darkenColor =
    fraction: hex:
    let
      hexDigits = "0123456789abcdef";
      hexToInt =
        c:
        let
          lower = lib.toLower c;
          idx = lib.lists.findFirstIndex (x: x == lower) null (lib.stringToCharacters hexDigits);
        in
        if idx != null then idx else 0;
      parseChannel = a: b: hexToInt a * 16 + hexToInt b;
      clamp =
        v:
        if v < 0 then
          0
        else if v > 255 then
          255
        else
          v;
      toHex =
        n:
        let
          hi = builtins.elemAt (lib.stringToCharacters hexDigits) (n / 16);
          lo = builtins.elemAt (lib.stringToCharacters hexDigits) (lib.mod n 16);
        in
        "${hi}${lo}";
    in
    assert
      (builtins.stringLength hex == 7 && builtins.substring 0 1 hex == "#")
      || throw "darkenColor: expected '#rrggbb' (7 chars), got '${hex}'";
    let
      chars = lib.stringToCharacters hex;
      r = parseChannel (builtins.elemAt chars 1) (builtins.elemAt chars 2);
      g = parseChannel (builtins.elemAt chars 3) (builtins.elemAt chars 4);
      b = parseChannel (builtins.elemAt chars 5) (builtins.elemAt chars 6);
      factor = 1.0 - fraction;
      newR = clamp (builtins.floor (r * factor + 0.5));
      newG = clamp (builtins.floor (g * factor + 0.5));
      newB = clamp (builtins.floor (b * factor + 0.5));
    in
    "#${toHex newR}${toHex newG}${toHex newB}";

  # mkColorReplacer :: { colors :: AttrSet, prefix :: Str?, suffix :: Str? } -> (Str -> Str)
  # Replace color placeholders (@@key@@) in strings with actual color values.
  # Example: mkColorReplacer {colors = {base00 = "#282828";}} "@@base00@@" => "#282828"
  mkColorReplacer =
    {
      colors,
      prefix ? "@@",
      suffix ? "@@",
    }:
    let
      keys = builtins.attrNames colors;
      oldStrs = map (k: "${prefix}${k}${suffix}") keys;
      newStrs = map (k: colors.${k}) keys;
    in
    builtins.replaceStrings oldStrs newStrs;

  # mkBoolOpt :: Bool -> Str -> Option
  # Boolean option shorthand used by NixOS feature modules.
  mkBoolOpt =
    default: desc:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = desc;
    };

  # mkProfile :: Str -> Bool -> Option
  # Profile option shorthand for enabling package sets.
  mkProfile =
    name: default:
    lib.mkOption {
      type = lib.types.bool;
      inherit default;
      description = "Enable ${name} package set.";
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
        name = "${keyPrefix}${toString ws.number}";
        value = "${commandPrefix} \"${mkWorkspaceName ws}\"";
      }) workspaces
    );

  # Validation helpers
  inherit
    validateSecretExists
    validateSecretEncrypted
    mkSecretValidation
    ;

  # Devshell helpers
  inherit mkDevshellMotd mkShellScript;

  # Color helpers
  inherit darkenColor mkColorReplacer;

  # Option + profile helpers
  inherit mkBoolOpt mkProfile;

  # Polybar helpers
  inherit mkPolybarTwoTone mkPolybarTwoToneState;
}
