{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Nix settings
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      trusted-users = [ "jga" ];
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # Networking
  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  # Timezone
  time.timeZone = "Europe/Copenhagen";

  # Locale support (hosts may override defaultLocale)
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "da_DK.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings =
    let
      defaultLocale =
        if
          lib.hasAttr "i18n" config
          && lib.hasAttr "defaultLocale" config.i18n
          && config.i18n.defaultLocale != null
        then
          config.i18n.defaultLocale
        else
          "en_US.UTF-8";
    in
    {
      LC_ADDRESS = defaultLocale;
      LC_IDENTIFICATION = defaultLocale;
      LC_MEASUREMENT = defaultLocale;
      LC_MONETARY = defaultLocale;
      LC_NAME = defaultLocale;
      LC_NUMERIC = defaultLocale;
      LC_PAPER = defaultLocale;
      LC_TELEPHONE = defaultLocale;
      LC_TIME = defaultLocale;
    };

  # X / Plasma defaults
  services.xserver.enable = true;
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
    defaultSession = "plasma";
  };

  qt.enable = true;
  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = true;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [ ];

  # Common services
  services.netbird.enable = true;
  services.fwupd.enable = true;

  # Hardware defaults
  hardware.sensor.iio.enable = true;
  hardware.graphics.enable = true;

  # Virtualisation
  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true; # virt-manager/other tools

  # Audio
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;

  services.libinput.enable = true;

  # Convenience utilities
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ ];

  # Allow non-free packages
  nixpkgs.config.allowUnfree = true;

  # Desktop environment helper
  environment.etc."environment.d/desktop-environment.conf".text = ''
    [Environment]
    DESKTOP_SESSION=$XDG_SESSION_DESKTOP
  '';

  # SSH askpass helper (default to KDE ksshaskpass)
  programs.ssh.askPassword = lib.mkForce (
    if builtins.getEnv "DESKTOP_SESSION" == "plasma" then
      "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
    else if builtins.getEnv "DESKTOP_SESSION" == "gnome" then
      "${pkgs.seahorse}/libexec/seahorse/ssh-askpass"
    else
      "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass"
  );

  security.sudo.package = pkgs.sudo.override { withInsults = true; };

  # No swap by default
  swapDevices = lib.mkForce [ ];

  # Some environment vars
  environment.variables.KWIN_DRM_PREFER_COLOR_DEPTH = "24";

  console.keyMap = "dk-latin1";

  # Basic user
  users.users.jga = {
    isNormalUser = true;
    description = "Jakob Stender Guldberg";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
    packages = with pkgs; [
      libsecret
    ];
  };

  # Common system packages
  environment.systemPackages = with pkgs; [
    git
    bat
  ];

  # Common displaylink service and video drivers
  services.xserver.videoDrivers = [
    "displaylink"
    "modesetting"
    "nvidia"
  ];

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

  # Programs commonly used
  programs.niri.enable = true;

  # Specialisation (shared)
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

  # Boot & kernel defaults (shared)
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

  # Firewall default
  networking.firewall = {
    enable = true;
  };

  system.stateVersion = "24.05";
}
