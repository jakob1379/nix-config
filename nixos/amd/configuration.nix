{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "amd";
  programs.fuse.userAllowOther = true;

  i18n.defaultLocale = "da_DK.UTF-8";
  # programs.gnupg.agent = {
  #   enable = false;
  #   enableSSHSupport = true;
  #   pinentryPackage = pkgs.pinentry-gtk2;
  # };
  services.pcscd.enable = true;

  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  # Explicitly set plasma as default session (inherited from common.nix but made explicit here)
  services.displayManager.defaultSession = "plasma";

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # dynamic swap
  services.swapspace.enable = true;

  # amd graphics
  boot.initrd.kernelModules = lib.mkAfter [ "amdgpu" ];
  services.xserver.videoDrivers = lib.mkAfter [ "amdgpu" ];

  # fingerprint
  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-elan;

  system.stateVersion = lib.mkForce "25.05";

}
