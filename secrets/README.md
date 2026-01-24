# Secrets (sops-nix)

This repo uses sops-nix for encrypted secrets. The flow is:

1) Generate an age key (or convert SSH key)
   - age-keygen -o ~/.config/sops/age/keys.txt
   - ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt

2) Put your age public key into .sops.yaml (replace age1CHANGE-ME).

3) Create an encrypted secrets file:
   - sops secrets/example.yaml

4) Reference secrets in NixOS or Home Manager:
   - NixOS: sops.secrets.<name>.sopsFile = "${inputs.self}/secrets/example.yaml";
   - HM:    sops.secrets.<name>.sopsFile = "${inputs.self}/secrets/example.yaml";

Notes:
- Do not commit unencrypted secrets.
- The sops key file location is set in nixos-modules/secrets.nix and home-modules/secrets.nix.
