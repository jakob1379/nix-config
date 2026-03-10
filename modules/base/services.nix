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
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg mountPath}";
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
            ${remote}:${remotePath} ${lib.escapeShellArg mountPath}
        '';
        ExecStop = "fusermount -u ${lib.escapeShellArg mountPath}";
        Type = "notify";
        Restart = "on-failure";
        RestartSec = "10s";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

  varietyWallpaperPointerFile = "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt";
  niriGeneratedFilesDir = "${config.xdg.configHome}/niri/generated";
  niriFocusGradientFile = "${niriGeneratedFilesDir}/wallust-focus-ring.kdl";
  niriWindowBorderRulesFile = "${niriGeneratedFilesDir}/window-border-rules.kdl";
  vicinaeThemesDir = "${config.xdg.dataHome}/vicinae/themes";
  vicinaeWallustDarkThemeFile = "${vicinaeThemesDir}/wallust-dark.toml";
  vicinaeWallustLightThemeFile = "${vicinaeThemesDir}/wallust-light.toml";

  noctaliaWallpaperSyncScript = pkgs.writeShellApplication {
    name = "noctalia-sync-variety-wallpaper";
    runtimeInputs = [
      pkgs.noctalia-shell
      pkgs.procps
    ];
    text = builtins.readFile ../../dotfiles/niri/scripts/sync-noctalia-variety-wallpaper.sh;
  };

  niriSessionExecCondition = "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg "${pkgs.coreutils}/bin/printenv XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qi niri"}";
  lockScreenCommand = "${pkgs.noctalia-shell}/bin/noctalia-shell ipc --newest call lockScreen lock";
  niriFocusGradientSyncScript = pkgs.writeShellApplication {
    name = "sync-niri-focus-gradient";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.niri
      pkgs.procps
    ];
    text = builtins.readFile ../../dotfiles/niri/scripts/sync-focus-gradient.sh;
  };

  niriWindowBorderRulesSyncScript = pkgs.writeShellApplication {
    name = "sync-niri-window-border-rules";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.diffutils
      pkgs.niri
      pkgs.procps
      pkgs.python3
    ];
    text = builtins.readFile ../../dotfiles/niri/scripts/sync-window-border-rules.sh;
  };

  niriWindowBorderRulesWatchScript = pkgs.writeShellApplication {
    name = "watch-niri-window-border-rules";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.niri
      pkgs.procps
    ];
    text = builtins.readFile ../../dotfiles/niri/scripts/watch-window-border-rules.sh;
  };

  vicinaeThemeSyncScript = pkgs.writeShellApplication {
    name = "sync-vicinae-theme";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ../../dotfiles/niri/scripts/sync-vicinae-theme.sh;
  };

  noctaliaWallpaperSyncCommand = "${noctaliaWallpaperSyncScript}/bin/noctalia-sync-variety-wallpaper ${lib.escapeShellArg varietyWallpaperPointerFile}";
  niriFocusGradientSyncCommand =
    "${niriFocusGradientSyncScript}/bin/sync-niri-focus-gradient "
    + "${lib.escapeShellArg "${config.xdg.cacheHome}/wallust"} "
    + "${lib.escapeShellArg "${config.xdg.configHome}/noctalia/colors.json"} "
    + "${lib.escapeShellArg niriFocusGradientFile}";
  vicinaeThemeSyncCommand =
    "${vicinaeThemeSyncScript}/bin/sync-vicinae-theme "
    + "${lib.escapeShellArg "${config.xdg.cacheHome}/wallust"} "
    + "${lib.escapeShellArg vicinaeWallustDarkThemeFile} "
    + "${lib.escapeShellArg vicinaeWallustLightThemeFile}";
  niriWindowBorderRulesWatchCommand =
    "${niriWindowBorderRulesWatchScript}/bin/watch-niri-window-border-rules "
    + "${lib.escapeShellArg "${niriWindowBorderRulesSyncScript}/bin/sync-niri-window-border-rules"} "
    + "${lib.escapeShellArg niriWindowBorderRulesFile}";

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
              ExecStart = "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg "if ${pkgs.coreutils}/bin/printenv XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qi niri; then export XDG_CURRENT_DESKTOP=sway; fi; exec ${pkgs.variety}/bin/variety"}";
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
                  ${pkgs.bash}/bin/bash -c '${pkgs.wallust}/bin/wallust run -k \"$(<${lib.escapeShellArg "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt"})\"'
                '';
                ExecStartPost = "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg "${niriFocusGradientSyncCommand}; ${vicinaeThemeSyncCommand}"}";
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

      noctaliaWallpaper = lib.mkOption {
        type = lib.types.attrs;
        default = {
          service = {
            "noctalia-sync-variety-wallpaper" = {
              Unit = {
                Description = "Sync Variety wallpaper to Noctalia";
                After = [ "graphical-session.target" ];
                StartLimitIntervalSec = 0;
              };
              Service = {
                ExecStart = noctaliaWallpaperSyncCommand;
                Type = "oneshot";
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
            };
          };

          path = {
            "noctalia-sync-variety-wallpaper" = {
              Unit = {
                Description = "Monitor Variety wallpaper changes for Noctalia";
                Wants = [ "noctalia-sync-variety-wallpaper.service" ];
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
              Path = {
                PathModified = varietyWallpaperPointerFile;
              };
            };
          };
        };
        description = "Systemd service and path to sync Variety wallpaper into Noctalia.";
      };

      niriWindowBorders = lib.mkOption {
        type = lib.types.attrs;
        default = {
          niri-window-border-rules = {
            Unit = {
              Description = "Sync per-window hashed border rules for Niri";
              After = [ "graphical-session.target" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Service = {
              ExecCondition = niriSessionExecCondition;
              ExecStart = niriWindowBorderRulesWatchCommand;
              Restart = "always";
              RestartSec = 2;
            };
          };
        };
        description = "Systemd service for dynamic per-window Niri border colors.";
      };

    };
  };

  config = {
    home.activation.ensureNiriFocusGradientFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target_file="${niriFocusGradientFile}"
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target_file")"
      if [ ! -f "$target_file" ]; then
        ${pkgs.coreutils}/bin/printf '%s\n' \
          'layout {' \
          '    focus-ring {' \
          '        active-gradient from="#80c8ff" to="#c7ff7f" angle=45' \
          '    }' \
          '}' > "$target_file"
      fi
    '';

    home.activation.ensureNiriWindowBorderRulesFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      target_file="${niriWindowBorderRulesFile}"
      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target_file")"
      if [ ! -f "$target_file" ]; then
        ${pkgs.coreutils}/bin/touch "$target_file"
      fi
    '';

    systemd = {
      user = {
        startServices = true;

        services = lib.mkMerge [
          config.customServices.rclone
          config.customServices.variety
          config.customServices.wallust.service
          config.customServices.noctaliaWallpaper.service
          config.customServices.niriWindowBorders
          (lib.mkIf config.services.swayidle.enable {
            swayidle.Service.ExecCondition = niriSessionExecCondition;
          })
        ];

        paths = lib.mkMerge [
          config.customServices.wallust.path
          config.customServices.noctaliaWallpaper.path
        ];
      };
    };

    services = {
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

      gpg-agent = {
        enable = true;
        pinentry.package = pkgs.pinentry-gtk2;
        pinentry.program = "pinentry-gtk-2";
      };

      udiskie = {
        enable = true;
        tray = "never";
      };

      unclutter = {
        enable = true;
        timeout = 5;
      };

      ssh-agent = {
        enable = true;
        enableBashIntegration = true;
      };

      swayidle = {
        enable = config.customPackages.enableGui;
        package = pkgs.swayidle;
        systemdTarget = "graphical-session.target";
        extraArgs = [ "-w" ];
        timeouts = [
          {
            timeout = 300;
            command = lockScreenCommand;
          }
          {
            timeout = 900;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
        events = {
          unlock = null;
          lock = lockScreenCommand;
          before-sleep = lockScreenCommand;
          after-resume = null;
        };
      };

      easyeffects.enable = true;
      mpris-proxy.enable = true;
      home-manager.autoExpire.enable = true;
    };

  };
}
