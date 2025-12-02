{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Create a function for rclone mount services
  createRcloneMountService =
    {
      name,
      remote ? "${name}",
      mountPath ? "${config.home.homeDirectory}/${name}",
      remotePath ? "/",
      configPath ? "${config.xdg.configHome}/rclone/rclone.conf",
      cacheMode ? "full",
    }:
    {
      Unit = {
        Description = "Rclone mount service for ${name}";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
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
            --vfs-cache-mode "${cacheMode}" \
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
  options = {
    customServices = {
      rclone = lib.mkOption {
        type = lib.types.attrs;
        default = {
          rclone-mount-dropbox-private = createRcloneMountService { name = "dropbox-private"; };
          rclone-mount-onedrive-ku-crypt = createRcloneMountService {
            name = "onedrive-ku-crypt";
            cacheMode = "off";
          };
          rclone-mount-onedrive-ku = createRcloneMountService { name = "onedrive-ku"; };
        };
        description = "Systemd services for rclone mounts.";
      };

      pywal = lib.mkOption {
        type = lib.types.attrs;
        default = {
          pywal-apply-variety = {
            Unit = {
              Description = "Apply pywal theme based on Variety wallpaper";
              After = [
                "graphical-session.target"
                "network-online.target"
                "rclone-mount-dropbox-private.service"
              ];
              Wants = [
                "network-online.target"
                "rclone-mount-dropbox-private.service"
              ];
              Requires = [ "rclone-mount-dropbox-private.service" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${
                pkgs.writeShellApplication {
                  name = "pywal-apply";
                  runtimeInputs = [
                    pkgs.pywal16
                    pkgs.coreutils
                    pkgs.imagemagick
                  ];
                  text = ''
                    set -e
                    wal -ni "$(cat ${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt)" && wal -R
                  '';
                }
              }/bin/pywal-apply";
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
        };
        description = "Systemd service for applying pywal theme.";
      };

      variety = lib.mkOption {
        type = lib.types.attrs;
        default = {
          variety = {
            Unit = {
              Description = "Launch Variety wallpaper changer";
              After = [
                "graphical-session.target"
                "network-online.target"
                "rclone-mount-dropbox-private.service"
              ];
              Wants = [
                "network-online.target"
                "rclone-mount-dropbox-private.service"
              ];
              Requires = [ "rclone-mount-dropbox-private.service" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Service = {
              ExecStart = "${pkgs.variety}/bin/variety --show-current";
              Restart = "on-failure";
              RestartSec = 10;
            };
          };
        };
        description = "Systemd service for Variety wallpaper changer.";
      };

      pywalPath = lib.mkOption {
        type = lib.types.attrs;
        default = {
          pywal-apply-variety = {
            Unit = {
              Description = "Monitor wallpaper file for changes";
              After = [ "rclone-mount-dropbox-private.service" ];
              Wants = [
                "pywal-apply-variety.service"
                "rclone-mount-dropbox-private.service"
              ];
              Requires = [ "rclone-mount-dropbox-private.service" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Path = {
              PathModified = "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt";
            };
          };
        };
        description = "Systemd path for pywal service.";
      };
    };
  };

  config = {
    systemd = {
      user = {
        startServices = true;

        services = lib.mkMerge [
          config.customServices.rclone
          config.customServices.pywal
          config.customServices.variety
        ];

        paths = config.customServices.pywalPath;
      };
    };

    services = {
      emacs = {
        startWithUserSession = "graphical";
        enable = true;
        defaultEditor = true;
        client.arguments = [
          "--alternative-editor ''"
          "--reuse-frame"
          "--no-wait"
        ];
      };

      unclutter = {
        enable = true;
        timeout = 5;
      };

      ssh-agent = {
        enable = true;
        enableBashIntegration = true;
      };
      easyeffects.enable = true;
      mpris-proxy.enable = true;
      home-manager.autoExpire.enable = true;
    };
  };
}
