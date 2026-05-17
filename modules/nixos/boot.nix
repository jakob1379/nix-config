{ config, pkgs, ... }:

{
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.evdi ];
    initrd.kernelModules = [ "evdi" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    kernelPackages = pkgs.linuxKernel.packages.linux_7_0;
    kernelModules = [ ];
    kernelParams = [
      "acpi_backlight=native"
      "psmouse.synaptics_intertouch=0"
    ];
  };
}
