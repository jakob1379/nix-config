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

      wallust = lib.mkOption {
        type = lib.types.attrs;
        default = {
          service = {
            "wallust-apply-variety" = {
              Unit = {
                # Unit definition for the service
                Description = "Apply wallpaper colors with Wallust";
                After = [ "rclone-mount-dropbox-private.service" ];
                Wants = [ "rclone-mount-dropbox-private.service" ];
                Requires = [ "rclone-mount-dropbox-private.service" ];
              };
              Service = {
                # Service-specific configuration
                ExecStart = ''
                  ${pkgs.bash}/bin/bash -c '${pkgs.wallust}/bin/wallust run -k \"$(<${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt)\"'
                '';
                Type = "oneshot";
              };
              Install = {
                # Install-specific configuration
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };

          path = {
            "wallust-apply-variety" = {
              Unit = {
                # Unit definition for the path
                Description = "Monitor wallpaper file for changes for Wallust";
                After = [ "rclone-mount-dropbox-private.service" ];
                Wants = [
                  "wallust-apply-variety.service" # Reference the full service unit name here
                  "rclone-mount-dropbox-private.service"
                ];
                Requires = [ "rclone-mount-dropbox-private.service" ];
              };
              Install = {
                # Install-specific configuration
                WantedBy = [ "graphical-session.target" ];
              };
              Path = {
                # Path-specific configuration
                PathModified = "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt";
              };
            };
          };
        };
        description = "Systemd service and path for wallust to apply colors based on wallpaper changes.";
      };

    };
  };

  config = {
    systemd = {
      user = {
        startServices = true;

        services = lib.mkMerge [
          config.customServices.rclone
          config.customServices.variety
          config.customServices.wallust.service
        ];

        paths = lib.mkMerge [
          config.customServices.wallust.path
        ];
      };
    };

    services = {
      gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-gtk2;
        pinentry.program = "pinentry-gtk-2";
      };

      emacs = {
        package = pkgs.emacs-pgtk;
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
