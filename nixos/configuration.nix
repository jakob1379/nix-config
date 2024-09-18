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

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # enable the KDE
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    # plasma-browser-integration
    # konsole
    # oxygen
  ];

  # I want to use KPXC instead
  # services.gnome.gnome-keyring.enable = lib.mkForce false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "dk-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sensors for lenovo to register screen orientation
  hardware.sensor.iio.enable = true;

  # enable fwupd: a simple daemon allowing you to update some devices' firmware, including UEFI for several machines.
  services.fwupd.enable = true;

  hardware.graphics = {
    enable = true;
  };

  # Enable blutooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Enable docker
  virtualisation.docker.enable = true;

  # Enable VirtualBox
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true; # virt-manager requires dconf to remember settings

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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
    description = "Jakob Guldberg Aaes";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
    packages = with pkgs; [
      #  thunder bird
      libsecret
      rclone
    ];
  };

  # Enable user defined systemd services
  systemd.user.services = {
    rclone-mount-dropbox-private = createRcloneMountService {
      name = "dropbox-private";
      remote = "dropbox-private";
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  # Define variables to dynamically set stuff depending on the desktop environment
  environment.etc."environment.d/desktop-environment.conf".text = ''
    [Environment]
    DESKTOP_SESSION=$XDG_SESSION_DESKTOP
  '';
  programs.ssh.askPassword = lib.mkForce (
    if builtins.getEnv "DESKTOP_SESSION" == "plasma" then
      "${pkgs.ksshaskpass}/bin/ksshaskpass"
    else if builtins.getEnv "DESKTOP_SESSION" == "gnome" then
      "${pkgs.seahorse}/libexec/seahorse/ssh-askpass"
    else
      "${pkgs.ksshaskpass}/bin/ksshaskpass" # Default to KDE's program
  );

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # some needs special allowance for FHS
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    ruff
  ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # Others, should not log into this machine
  services.openssh.enable = false;

  # Open ports in the firewall.
  networking.firewall.enable = true;
  services.fail2ban.enable = true;
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
