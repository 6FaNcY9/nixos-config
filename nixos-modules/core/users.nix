# Core: User accounts
# Always enabled (no option)
{
  pkgs,
  username,
  ...
}:
let
  userGroups = [
    "wheel"
    "networkmanager"
    "audio"
    "video"
  ];
in
{
  users = {
    defaultUserShell = pkgs.fish;

    users.${username} = {
      isNormalUser = true;
      description = username;
      extraGroups = userGroups;
    };
  };

  security = {
    sudo.wheelNeedsPassword = true;
  };
}
