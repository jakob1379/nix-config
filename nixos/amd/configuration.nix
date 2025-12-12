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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  # dynamic swap
  services.swapspace.enable = true;

  # amd graphics
  boot.initrd.kernelModules = lib.mkAfter [ "amdgpu" ];
  services.xserver.videoDrivers = lib.mkAfter [ "amdgpu" ];

  # Additional AMD GPU configuration
  hardware.graphics.enable32Bit = true;
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
  ];
  environment.variables = {
    ROC_ENABLE_PRE_VEGA = "1";
  };
  services.lact.enable = true;
  environment.systemPackages = with pkgs; [ clinfo ];

  # fingerprint
  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-elan;

  system.stateVersion = lib.mkForce "25.05";

}
