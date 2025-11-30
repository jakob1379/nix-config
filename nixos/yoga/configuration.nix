{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "yoga";
  programs.fuse.userAllowOther = true;

  i18n.defaultLocale = "da_DK.UTF-8";

  programs.gnupg.agent = {
    enable = false;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };
  services.pcscd.enable = true;

  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
  kernelModules = [ "kvm-intel" ];

  kernelParams = lib.mkAfter [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

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
