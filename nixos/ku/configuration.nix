# Minimal host-specific configuration for ku; common settings are in ../common.nix
{ config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  # Only machine-specific overrides should remain here.
  networking.hostName = "ku";

  # Keyboard layout for this host
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  programs.appimage.enable = true;

  # Allow fuse mounts for normal users on this machine
  programs.fuse.userAllowOther = true;

  # Enable the nvidia container toolkit only on this host
  hardware.nvidia-container-toolkit.enable = true;

  # Specialisation (shared)
  specialisation = {
    on-the-go.configuration = {
      system.nixos.tags = [ "on-the-go" ];
      hardware.nvidia = {
        prime = {
          offload = {
            enable = lib.mkForce true;
            enableOffloadCmd = lib.mkForce true;
          };
          sync.enable = lib.mkForce false;
        };
      };
    };
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:45:0:0";
    };
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

}
