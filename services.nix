{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Create a derivation for the script
  createRcloneMountService =
    {
      name,
      remote ? "${name}",
      mountPath ? "${config.home.homeDirectory}/${name}",
      remotePath ? "/",
      configPath ? "${config.xdg.configHome}/rclone/rclone.conf",
    }:
    {
      Unit = {
        Description = "Rclone mount service for ${name}";
      };

      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount \
            --allow-other \
            --attr-timeout 1h \
            --buffer-size=32M \
            --config "${configPath}" \
            --dir-cache-time 3h0m0s \
            --vfs-cache-max-age 6h \
            --vfs-cache-max-size 10G \
            --vfs-cache-mode full \
            --vfs-fast-fingerprint \
            ${remote}:${remotePath} ${mountPath}
        '';
        ExecStop = "fusermount -u ${mountPath}";
        Type = "notify";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

in
{

  services = {
    emacs = {
      startWithUserSession = "graphical";
      enable = true;
      defaultEditor = true;
      client.arguments = [
        "--reuse-frame"
        "--no-wait"
      ];
    };
    unclutter = {
      enable = true;
      timeout = 5;
    };
    ssh-agent.enable = true;
    easyeffects.enable = true;
    mpris-proxy.enable = true;
    # random-background = {
    #   enable = true;
    #   display = "fill";
    #   imageDirectory = "%h/dropbox-private/Andet/Favorites";
    # };
  };

  systemd.user.startServices = true;
  systemd.user.services = {
    # Create the rclone mount services by calling the function with the desired parameters using named arguments
    rclone-mount-dropbox-private = createRcloneMountService {
      name = "dropbox-private";
    };
    rclone-mount-onedrive-ku-crypt = createRcloneMountService {
      name = "onedrive-ku-crypt";
    };
    rclone-mount-onedrive-ku = createRcloneMountService {
      name = "onedrive-ku";
    };
    # rclone-mount-gdrive-private = createRcloneMountService {
    #   name = "gdrive-private";
    #   remote = "gdrive-private";
    # };
  };

  # pywal auto change
  systemd.user.services.pywal-apply-variety = {
    Unit = {
      Description = "Apply pywal theme based on Variety wallpaper";
      After = [ "graphical-session.target" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.writeShellScript "pywal-apply" ''
        set -e
        ${pkgs.pywal16}/bin/wal -ni "$(${pkgs.coreutils}/bin/cat ${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt)" && ${pkgs.pywal16}/bin/wal -R
      ''}";
      Restart = "on-failure";
      RestartSec = 5;
      StandardOutput = "journal";
      StandardError = "journal";
      Environment = [
        "SYSTEMD_LOG_LEVEL=debug"
        "PATH=${pkgs.imagemagick}/bin:$PATH"
      ];
    };
  };

  systemd.user.paths.pywal-apply-variety = {
    Unit = {
      Description = "Monitor wallpaper file for changes";
      Wants = [ "pywal-apply-variety.service" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
    Path = {
      PathModified = "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt";
    };
  };
}
