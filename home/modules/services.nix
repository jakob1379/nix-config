{
  config,
  pkgs,
  lib,
  ...
}:

let
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

  rcloneDropboxPrivateService = "rclone-mount-dropbox-private.service";
  dropboxPrivateMountPath = "${config.home.homeDirectory}/dropbox-private";
  varietyWallpaperPointerFile = "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt";
  niriWindowBorderRulesFile = "${config.xdg.configHome}/niri/generated/window-border-rules.kdl";

  niriSessionExecCondition = "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg "${pkgs.coreutils}/bin/printenv XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qi niri"}";

  niriWindowBorderRulesSyncScript = pkgs.writeShellApplication {
    name = "sync-niri-window-border-rules";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.diffutils
      pkgs.niri
      pkgs.procps
      pkgs.python3
    ];
    text = builtins.readFile ../../scripts/niri/sync-window-border-rules.sh;
  };

  niriWindowBorderRulesWatchScript = pkgs.writeShellApplication {
    name = "watch-niri-window-border-rules";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.niri
      pkgs.procps
    ];
    text = builtins.readFile ../../scripts/niri/watch-window-border-rules.sh;
  };

  varietyWallustTerminalColorsSyncScript = pkgs.writeShellApplication {
    name = "sync-variety-wallust-terminal-colors";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.wallust
    ];
    text = builtins.readFile ../../scripts/wallpaper/sync-variety-wallust-terminal-colors.sh;
  };

  varietyWallustTerminalColorsSyncCommand =
    "${varietyWallustTerminalColorsSyncScript}/bin/sync-variety-wallust-terminal-colors "
    + lib.escapeShellArg "${pkgs.variety}/bin/variety";

  niriWindowBorderRulesWatchCommand =
    "${niriWindowBorderRulesWatchScript}/bin/watch-niri-window-border-rules "
    + "${lib.escapeShellArg "${niriWindowBorderRulesSyncScript}/bin/sync-niri-window-border-rules"} "
    + "${lib.escapeShellArg niriWindowBorderRulesFile}";

in
{
  options = {
    customServices = {
      storage = lib.mkOption {
        type = lib.types.attrs;
        default = {
          rclone = {
            service = {
              rclone-mount-dropbox-private = createRcloneMountService { name = "dropbox-private"; };
            };
          };
        };
        description = "Systemd services for storage mounts.";
      };

      wallpaper = lib.mkOption {
        type = lib.types.attrs;
        default = {
          varietyWallpaper = {
            service = {
              variety = {
                Unit = {
                  Description = "Variety wallpaper changer";
                  After = [ rcloneDropboxPrivateService ];
                  Wants = [ rcloneDropboxPrivateService ];
                  Requires = [ rcloneDropboxPrivateService ];
                };
                Service = {
                  ExecStartPre = "${pkgs.util-linux}/bin/mountpoint -q ${lib.escapeShellArg dropboxPrivateMountPath}";
                  ExecStart = "${pkgs.variety}/bin/variety";
                  Restart = "on-failure";
                  RestartSec = 5;
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };

              "variety-wallust-terminal-colors" = {
                Unit = {
                  Description = "Sync terminal colors from Variety wallpaper";
                  After = [ rcloneDropboxPrivateService ];
                  Wants = [ rcloneDropboxPrivateService ];
                  Requires = [ rcloneDropboxPrivateService ];
                };
                Service = {
                  ExecStart = varietyWallustTerminalColorsSyncCommand;
                  TimeoutStartSec = 60;
                  Type = "oneshot";
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };
            };

            path = {
              "variety-wallust-terminal-colors" = {
                Unit = {
                  Description = "Watch Variety wallpaper pointer for terminal colors";
                  After = [ rcloneDropboxPrivateService ];
                  Wants = [
                    "variety-wallust-terminal-colors.service"
                    rcloneDropboxPrivateService
                  ];
                  Requires = [ rcloneDropboxPrivateService ];
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
                Path = {
                  PathChanged = varietyWallpaperPointerFile;
                };
              };
            };
          };
        };
        description = "Systemd services for wallpaper state.";
      };

      desktop = lib.mkOption {
        type = lib.types.attrs;
        default = {
          niriWindowBorders = {
            "niri-window-border-rules" = {
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
        };
        description = "Systemd services for desktop integration.";
      };
    };
  };

  config =
    let
      cfg = config.customServices;
      coreServices = {
        emacs = {
          package = pkgs.emacs-pgtk;
          startWithUserSession = false;
          enable = true;
          defaultEditor = true;
          client.arguments = [
            "--alternative-editor ''"
            "--reuse-frame"
            "--no-wait"
          ];
        };

        cachix-agent = {

        };

        gpg-agent = {
          enable = true;
          pinentry.package = pkgs.pinentry-gtk2;
          pinentry.program = "pinentry-gtk-2";
        };

        ssh-agent = {
          enable = true;
        };

        home-manager.autoExpire.enable = true;
      };

      guiServices = {
        udiskie = {
          enable = true;
          tray = "auto";
        };

        unclutter = {
          enable = true;
          timeout = 5;
        };

        waytorandr = {
          enable = true;
        };

        easyeffects.enable = true;
        mpris-proxy.enable = true;
      };
    in
    {
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
            (lib.mkIf config.customPackages.gui.enable (cfg.storage.rclone.service or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.varietyWallpaper.service or { }))
            (lib.mkIf config.customPackages.gui.enable cfg.desktop.niriWindowBorders)
            (lib.mkIf config.services.swayidle.enable {
              swayidle.Service.ExecCondition = niriSessionExecCondition;
            })
          ];

          paths = lib.mkMerge [
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.varietyWallpaper.path or { }))
          ];
        };
      };

      services = coreServices // lib.optionalAttrs config.customPackages.gui.enable guiServices;
    };
}
