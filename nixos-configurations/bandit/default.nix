{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
  ];

  networking.hostName = "bandit";

  roles = {
    desktop = true;
    laptop = true;
  };

  desktop.variant = "i3-xfce";

  # Host-specific hibernate resume settings
  boot = {
    resumeDevice = "/dev/disk/by-uuid/0629aaee-1698-49d1-b3e1-e7bb6b957cda";
    kernelParams = ["resume_offset=1959063"];
  };
}
