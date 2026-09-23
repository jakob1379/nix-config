{
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../common.nix
    ../../users/jsg.nix
  ];
  programs.gpu-screen-recorder = {
    enable = true;
    ui.enable = true;
  };
  networking.hostName = "amd";
  programs.fuse.userAllowOther = true;
  i18n.defaultLocale = "en_US.UTF-8";

  # PM Software vikunja
  services.vikunja = {
    enable = true;
    frontendScheme = "http";
    frontendHostname = "localhost";
  };

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
    enable = false;
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

  # Backups: restic to OneDrive. restic has no native OneDrive backend, so it
  # tunnels through rclone. Two root-owned secrets live outside this repo:
  #   /etc/restic/password     - repository password
  #   /etc/restic/rclone.conf  - rclone config holding the "onedrive-seeq" remote
  environment.systemPackages = [ pkgs.rclone ];

  # The restic module pins each unit's PATH to ssh only, so rclone has to be
  # added explicitly or the rclone backend cannot start.
  systemd.services = {
    restic-backups-onedrive-seeq.path = [ pkgs.rclone ];
    restic-backups-onedrive-seeq-maintenance.path = [ pkgs.rclone ];
  };

  services.restic.backups =
    let
      repo = {
        repository = "rclone:onedrive-seeq:backups/amd";
        rcloneConfigFile = "/etc/restic/rclone.conf";
        passwordFile = "/etc/restic/password";
        inhibitsSleep = true;
      };
    in
    {
      # Snapshots only, every four hours. forget/prune/check are deliberately
      # absent: prune repacks data, which over OneDrive is slow and rate
      # limited, so it belongs in the weekly maintenance set below.
      onedrive-seeq = repo // {
        initialize = true;
        pruneOpts = [ ];
        runCheck = false;

        paths = [
          "/home"
          "/etc"
          "/var/lib"
        ];

        extraBackupArgs = [
          "--one-file-system" # never descend into dropbox/onedrive/other fuse mounts
          "--exclude-caches" # honour CACHEDIR.TAG
        ];

        exclude = [
          # Cloud mount points, listed as well as --one-file-system so a stale
          # local copy is skipped on the days the mount happens to be down.
          "/home/*/dropbox-private"
          "/home/*/gdrive-private"
          "/home/*/gphotos-private"
          "/home/*/mega-private"
          "/home/*/onedrive-*"

          # Regenerable user data
          "/home/*/.cache"
          "/home/*/.local/share/Trash"
          "/home/*/.local/share/Steam"
          "/home/*/.var/app/*/cache"
          "/home/*/.android"
          "/home/*/.docker"
          "/home/*/.gradle/caches"
          "/home/*/.npm/_cacache"
          "/home/*/.cargo/registry"
          "/home/*/.rustup/toolchains"
          "/home/*/.pub-cache"
          "/home/*/.dspy_cache"
          "/home/*/.texlive*"
          "/home/*/go/pkg"
          "**/node_modules"
          "**/.direnv"
          "**/.venv"
          "**/__pycache__"
          "**/.mypy_cache"
          "**/.pytest_cache"
          "**/.ruff_cache"

          # Regenerable or oversized system state
          "/var/lib/clamav"
          "/var/lib/containers"
          "/var/lib/docker"
          "/var/lib/libvirt/images"
          "/var/lib/machines"
          "/var/lib/portables"
          "/var/lib/swapspace"
          "/var/lib/systemd/coredump"
        ];

        timerConfig = {
          OnCalendar = "*-*-* 00/4:00:00"; # 00, 04, 08, 12, 16, 20
          RandomizedDelaySec = "20m";
          Persistent = true; # catch up a run missed while powered off
        };
      };

      # Retention and integrity check. No paths, so this set only runs
      # "restic forget --prune" and "restic check" against the same repository.
      onedrive-seeq-maintenance = repo // {
        initialize = false;
        createWrapper = false;

        pruneOpts = [
          "--keep-last 24" # every snapshot of the last ~4 days
          "--keep-daily 14"
          "--keep-weekly 8"
          "--keep-monthly 12"
          "--keep-yearly 3"
        ];

        runCheck = true;
        checkOpts = [ "--with-cache" ];

        timerConfig = {
          OnCalendar = "Sun *-*-* 03:00:00";
          RandomizedDelaySec = "30m";
          Persistent = true;
        };
      };
    };

  services.desktopManager.gnome.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;

}
