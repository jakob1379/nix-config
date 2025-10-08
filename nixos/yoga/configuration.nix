{ config, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "yoga";

  i18n.defaultLocale = "da_DK.UTF-8";

  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
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

  system.stateVersion = config.system.stateVersion;
}
