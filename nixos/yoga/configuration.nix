{
  config,
  pkgs,
  lib,
  ...
}:
let
  LC_LOCALE = "da_DK.UTF-8";
  createRcloneMountService =
    {
      name,
      remote,
      mountPath ? "/home/jga/${name}",
      remotePath ? "/",
    }:
    {
      description = "Rclone mount service for ${name}";
      after = [ "network-online.target" ];
      restartIfChanged = true;
      enable = true;
      wantedBy = [
        "default.target"
        "network-online.target"
      ];

      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
        ExecStart = "${pkgs.rclone}/bin/rclone mount --config /home/jga/.config/rclone/rclone.conf --vfs-fast-fingerprint --vfs-cache-mode full ${remote}:${remotePath} ${mountPath}";
        Type = "notify";
        Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
      };
    };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Host-specific networking
  networking.hostName = "nixos"; # Define your hostname.
  networking.firewall.enable = true;

  # Select internationalisation properties (override defaultLocale)
  i18n.defaultLocale = "${LC_LOCALE}";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "${LC_LOCALE}";
    LC_IDENTIFICATION = "${LC_LOCALE}";
    LC_MEASUREMENT = "${LC_LOCALE}";
    LC_MONETARY = "${LC_LOCALE}";
    LC_NAME = "${LC_LOCALE}";
    LC_NUMERIC = "${LC_LOCALE}";
    LC_PAPER = "${LC_LOCALE}";
    LC_TELEPHONE = "${LC_LOCALE}";
    LC_TIME = "${LC_LOCALE}";
  };

  # Xkb layout for this host
  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  # KDE specific overrides
  environment.plasma6.excludePackages = with pkgs.kdePackages; [ ];

  # Enable sensors and audio settings (already in common, kept minimal here)
  hardware = {
    sensor.iio.enable = true;
    graphics = {
      enable = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    pulseaudio.enable = false;
  };

  # Enable docker and libvirtd (inherited from common)

  # programs specific to this host
  programs.niri.enable = true;

  # DisplayLink service (host-specific)
  systemd.services.displaylink = {
    enable = true;
    description = "DisplayLink Manager";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    requires = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      Restart = "on-failure";
      RestartSec = 5;
      User = "root";
      Group = "root";
    };
  };

  services.xserver.videoDrivers = [
    "displaylink"
    "modesetting"
    "nvidia"
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

  # User modifications: append group and packages
  users.users.jga = lib.mkForce (
    config.users.users.jga
    // {
      extraGroups = config.users.users.jga.extraGroups ++ [ "netbird-jgalabs" ];
      packages = config.users.users.jga.packages;
    }
  );

  # Enable user defined systemd services for rclone mounts
  systemd.user.services = {
    rclone-mount-dropbox-private = createRcloneMountService {
      name = "dropbox-private";
      remote = "dropbox-private";
    };
  };

  # Append displaylink to system packages
  environment.systemPackages = lib.mkForce (
    config.environment.systemPackages ++ [ pkgs.displaylink ]
  );

  environment.variables = {
    KWIN_DRM_PREFER_COLOR_DEPTH = "24";
  };

  environment.etc."environment.d/desktop-environment.conf".text = ''
    [Environment]
    DESKTOP_SESSION=$XDG_SESSION_DESKTOP
  '';

  programs.ssh.askPassword = lib.mkForce (
    if builtins.getEnv "DESKTOP_SESSION" == "plasma" then
      "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
    else if builtins.getEnv "DESKTOP_SESSION" == "gnome" then
      "${pkgs.seahorse}/libexec/seahorse/ssh-askpass"
    else
      "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass" # Default to KDE's program
  );

  swapDevices = lib.mkForce [ ];

  boot = {
    extraModulePackages = [ config.boot.kernelPackages.evdi ];
    initrd.kernelModules = [ "evdi" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "acpi_backlight=native"
      "psmouse.synaptics_intertouch=0"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];
  };

  # No swap
  swapDevices = lib.mkForce [ ];

  networking.firewall = {
    enable = true;
  };

  system.stateVersion = config.system.stateVersion;
}
