# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  LC_LOCALE = "en_US.UTF-8";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable flakes and nix commands
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  networking.hostName = "ku"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Use systemd-resolved for dns
  services.resolved.enable = true;
  networking.networkmanager.dns = "systemd-resolved";

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "${LC_LOCALE}";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "da_DK.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
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
  };
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # enable the KDE
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
  };

  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = true;
  };
  environment.plasma6.excludePackages = (
    with pkgs.kdePackages;
    [
      kate
    ]
  );

  # # Define specializations
  # specialisation = {};

  # I want to use KPXC instead
  # services.gnome.gnome-keyring.enable = lib.mkForce false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "dk-latin1";

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint
      hplip
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable sensors for lenovo to register screen orientation
  hardware.sensor.iio.enable = true;

  # enable fwupd: a simple daemon allowing you to update some devices' firmware, including UEFI for several machines.
  services.fwupd.enable = true;

  # setup nvidia
  # https://nixos.wiki/wiki/Nvidia

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  # hardware.firmware = [ displaylink ];
  services.xserver.videoDrivers = [
    "displaylink"
    "nvidia"
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    prime = {
      offload = {
        enable = true;
        #   enableOffloadCmd = true;
      };
      # sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:45:0:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  # Enable bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      Experimental = "true";
      FastConnectable = "true";
      Enable = "Source,Sink,Media,Socket";
    };
  };

  # Enable docker
  virtualisation.docker.enable = true;

  # Enable VirtualBox
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jga = {
    isNormalUser = true;
    description = "Jakob Stender Guldberg";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
      "netbird-darerl"
      "netbird-daisy"
    ];
    packages = with pkgs; [
      #  thunder bird
      libsecret
      rclone
    ];
  };

  # allow fuse to mount for other users
  programs.fuse.userAllowOther = true;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs = {
    config.allowUnfree = true;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    bat
  ];

  # Define variables to dynamically set stuff depending on the desktop environment
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  security.sudo.package = pkgs.sudo.override { withInsults = true; };

  security.pam = {
    u2f = {
      enable = true;
      settings.cue = true;
    };
    yubico = {
      enable = true;
      control = "sufficient";
      mode = "challenge-response";
      id = [
        "22313001"
        "22313027"
      ];
    };
    services = {
      login.u2fAuth = true;
      sudo.u2fAuth = true;
    };
  };

  # some needs special allowance for FHS
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # Others, should not log into this machine
  services.openssh.enable = false;

  # We also want to enable netbird as our VPN of choice
  services = {
    netbird = {
      enable = true;
      clients = {
        darerl.port = 51822;
        daisy.port = 51823;
      };
    };
  };

  boot.kernelModules = [ "kvm-intel" ];

  boot.kernelParams = [
    "acpi_backlight=native"
    "psmouse.synaptics_intertouch=0"
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  # no swap please.
  swapDevices = lib.mkForce [ ];

  # Open ports in the firewall.
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
