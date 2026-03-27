{
  config,
  pkgs,
  lib,
  ...
}:
let
  mkGraphicsProfile =
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
      hardware.nvidia.prime = {
        offload = {
          enable = lib.mkForce onTheGo;
          enableOffloadCmd = lib.mkForce onTheGo;
        };
        sync.enable = lib.mkForce (!onTheGo);
      };
    };

  mkDesktopSpecialisation =
    {
      name,
      session,
      onTheGo ? false,
    }:
    {
      inherit name;
      value.configuration = {
        services.displayManager.defaultSession = lib.mkForce session;
      }
      // mkGraphicsProfile {
        desktopTag = session;
        inherit onTheGo;
      };
    };
in
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "yoga";
  programs.fuse.userAllowOther = true;

  i18n.defaultLocale = "en_US.UTF-8";

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

  specialisation = builtins.listToAttrs [
    (mkDesktopSpecialisation {
      name = "niri-docked";
      session = "niri";
    })
    (mkDesktopSpecialisation {
      name = "niri-on-the-go";
      session = "niri";
      onTheGo = true;
    })
    (mkDesktopSpecialisation {
      name = "plasma-docked";
      session = "plasma";
    })
    (mkDesktopSpecialisation {
      name = "plasma-on-the-go";
      session = "plasma";
      onTheGo = true;
    })
  ];

  services.xserver.videoDrivers = lib.mkAfter [ "nvidia" ];
  boot.kernelModules = [ "kvm-intel" ];

  boot.kernelParams = lib.mkAfter [
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
