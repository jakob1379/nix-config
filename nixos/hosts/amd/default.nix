{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../common.nix
    ../../users/jsg.nix
    inputs.flyline.nixosModules.default
  ];

  # Readline replacement (syntax highlighting, autosuggestions, fuzzy
  # history) as a loadable Bash builtin. Replaces ble.sh, which cost
  # ~1900ms per interactive shell; flyline measures ~35ms.
  # Note: flyline owns Ctrl+R, so atuin's search UI is not reachable.
  programs.flyline.enable = true;
  programs.gpu-screen-recorder.enable = true;
  networking.hostName = "amd";
  programs.fuse.userAllowOther = true;
  i18n.defaultLocale = "en_US.UTF-8";

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

  users.users.jsg.extraGroups = [
    "netbird"
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    # package = pkgs.pulseaudioFull;
    settings.General.Experimental = true;
  };

  # dynamic swap
  services.swapspace.enable = true;

  services.cachix-watch-store = {
    enable = true;
    cacheName = "jgalabs-homelab";
    cachixTokenFile = "/etc/cachix-watch-store.token";
  };

  # amd graphics
  boot.initrd.kernelModules = lib.mkAfter [ "amdgpu" ];
  services.xserver.videoDrivers = lib.mkAfter [ "amdgpu" ];

  # fingerprint
  services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  system.stateVersion = lib.mkForce "25.05";

  services.desktopManager.gnome.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;

}
