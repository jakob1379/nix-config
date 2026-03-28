{
  lib,
  ...
}:
let
  desktopSessions = [
    "niri"
    "plasma"
  ];

  mobilityProfiles = [
    {
      suffix = "docked";
      onTheGo = false;
    }
    {
      suffix = "on-the-go";
      onTheGo = true;
    }
  ];

  mkDesktopProfile =
    {
      desktopTag,
      onTheGo ? false,
    }:
    {
      system.nixos.tags = [
        desktopTag
      ]
      ++ lib.optional onTheGo "on-the-go"
      ++ lib.optional (!onTheGo) "docked";
    };

  mkDesktopSpecialisations =
    profileConfig:
    builtins.listToAttrs (
      lib.concatMap (
        session:
        map (profile: {
          name = "${session}-${profile.suffix}";
          value.configuration = {
            services.displayManager.defaultSession = lib.mkForce session;
          }
          // profileConfig {
            desktopTag = session;
            inherit (profile) onTheGo;
          };
        }) mobilityProfiles
      ) desktopSessions
    );
in
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];
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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    # package = pkgs.pulseaudioFull;
    settings.General.Experimental = true;
  };

  # dynamic swap
  services.swapspace.enable = true;

  # amd graphics
  boot.initrd.kernelModules = lib.mkAfter [ "amdgpu" ];
  services.xserver.videoDrivers = lib.mkAfter [ "amdgpu" ];

  specialisation = mkDesktopSpecialisations mkDesktopProfile;

  # fingerprint
  services.fprintd.enable = true;
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  system.stateVersion = lib.mkForce "25.05";

}
