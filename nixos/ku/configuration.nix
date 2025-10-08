# Minimal host-specific configuration for ku; common settings are in ../common.nix
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  # Only machine-specific overrides should remain here.
  networking.hostName = "ku";

  services.netbird = {
    ui.enable = true;
    tunnels.jgalabs.port = 52821;
  };

  # Printing and mDNS are specific to this host
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

  # Host-specific excluded plasma packages
  environment.plasma6.excludePackages = with pkgs.kdePackages; [ kate ];

  # Keyboard layout for this host
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Allow fuse mounts for normal users on this machine
  programs.fuse.userAllowOther = true;

  # Enable the nvidia container toolkit only on this host
  hardware.nvidia-container-toolkit.enable = true;

  # Append host-specific group for the main user
  users.users.jga = lib.mkForce (
    config.users.users.jga
    // {
      extraGroups = config.users.users.jga.extraGroups ++ [ "netbird-jgalabs" ];
    }
  );

  # Keep U2F/Yubico PAM settings for this host
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
}
