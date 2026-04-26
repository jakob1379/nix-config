{
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "homelab";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Copenhagen";

  services.qemuGuest.enable = true;
  services.resolved.enable = true;
  services.netbird.enable = true;

  boot.loader.grub.enable = true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.growPartition = true;
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.arp_ignore" = 1;
    "net.ipv4.conf.all.arp_announce" = 2;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [
        "root"
        "deploy"
      ];
      auto-optimise-store = true;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    nano
    curl
    bat
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  users.users.jsg = {
    isNormalUser = true;
    description = "Jakob Stender Guldberg";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    initialHashedPassword = "$y$j9T$VJd3I/BqxcnLrCv0HnRx1.$IhfmwBjIiqWz0seqIJ19ujfowZRV6718lzsFZ4cdrp5";
  };

  virtualisation.docker.enable = true;

  security.sudo.package = pkgs.sudo.override { withInsults = true; };

  system.stateVersion = "25.05";
}
