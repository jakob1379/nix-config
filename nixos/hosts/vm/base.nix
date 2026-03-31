{
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = lib.mkDefault "vm";
  services.qemuGuest.enable = lib.mkDefault true;

  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.devices = [ "nodev" ];
  boot.growPartition = lib.mkDefault true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  environment.systemPackages = with pkgs; [
    git
    nano
    curl
  ];

  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  services.openssh = {
    enable = lib.mkDefault true;
    settings.PasswordAuthentication = lib.mkDefault false;
    settings.KbdInteractiveAuthentication = lib.mkDefault false;
  };

  programs.ssh.startAgent = lib.mkDefault true;
}
