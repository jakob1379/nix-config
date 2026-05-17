{ lib, ... }:

{
  services.fwupd.enable = true;
  services.udisks2.enable = true;

  hardware.sensor.iio.enable = true;
  hardware.graphics.enable = true;

  services.libinput.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = [ ];

  swapDevices = lib.mkForce [ ];

  services.gnome.gnome-keyring.enable = false;
}
