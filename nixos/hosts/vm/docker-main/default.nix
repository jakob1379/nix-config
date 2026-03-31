{ ... }:
{
  imports = [
    ../base.nix
  ];

  networking.hostName = "vm-docker-main";

  nix.settings.trusted-users = [
    "root"
    "deploy"
  ];

  security.sudo.wheelNeedsPassword = false;

  users.users.jsg = {
    isNormalUser = true;
    description = "Jakob Stender Guldberg";
    extraGroups = [
      "wheel"
      "docker"
    ];
    openssh.authorizedKeys.keys = [ ];
  };

  virtualisation.docker.enable = true;

  system.stateVersion = "25.05";
}
