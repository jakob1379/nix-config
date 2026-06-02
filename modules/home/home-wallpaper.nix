{
  config,
  pkgs,
  lib,
  ...
}:

let
  rcloneDropboxPrivateService = "rclone-mount-dropbox-private.service";
  dropboxPrivateMountPath = "${config.home.homeDirectory}/dropbox-private";
  varietyWallpaperPointerFile = "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt";
  wallpaperStateDir = "${config.xdg.stateHome}/wallpaper";
  currentWallpaperStateFile = "${wallpaperStateDir}/current-wallpaper";
  wallustPaletteStateFile = "${wallpaperStateDir}/wallust-palette.json";

  noctaliaWallpaperSyncScript = pkgs.writeShellApplication {
    name = "sync-noctalia-wallpaper";
    runtimeInputs = [
      pkgs.noctalia-shell
      pkgs.procps
      pkgs.coreutils
    ];
    text = builtins.readFile ../../scripts/wallpaper/sync-noctalia-wallpaper.sh;
  };

  currentWallpaperStateSyncScript = pkgs.writeShellApplication {
    name = "update-current-wallpaper-state";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ../../scripts/wallpaper/update-current-wallpaper-state.sh;
  };

  wallustPaletteStateSyncScript = pkgs.writeShellApplication {
    name = "update-wallust-palette-state";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ../../scripts/wallpaper/update-wallust-palette-state.sh;
  };

  noctaliaWallpaperSyncCommand =
    "${noctaliaWallpaperSyncScript}/bin/sync-noctalia-wallpaper "
    + lib.escapeShellArg currentWallpaperStateFile;
  currentWallpaperStateSyncCommand =
    "${currentWallpaperStateSyncScript}/bin/update-current-wallpaper-state "
    + "${lib.escapeShellArg varietyWallpaperPointerFile} "
    + lib.escapeShellArg currentWallpaperStateFile;
  runWallustFromCurrentWallpaperScript = pkgs.writeShellApplication {
    name = "run-wallust-from-current-wallpaper";
    runtimeInputs = [
      pkgs.wallust
      wallustPaletteStateSyncScript
    ];
    text = builtins.readFile ../../scripts/wallpaper/run-wallust-from-current-wallpaper.sh;
  };
  runWallustFromCurrentWallpaperCommand =
    "${runWallustFromCurrentWallpaperScript}/bin/run-wallust-from-current-wallpaper "
    + "${lib.escapeShellArg currentWallpaperStateFile} "
    + "${lib.escapeShellArg "${config.xdg.cacheHome}/wallust"} "
    + lib.escapeShellArg wallustPaletteStateFile;
in
{
  options.customServices.wallpaper = lib.mkOption {
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

          "variety-wallpaper-updated" = {
            Unit = {
              Description = "Resolve current wallpaper from Variety";
              StartLimitIntervalSec = 0;
              After = [ rcloneDropboxPrivateService ];
              Wants = [ rcloneDropboxPrivateService ];
              Requires = [ rcloneDropboxPrivateService ];
            };
            Service = {
              ExecStart = currentWallpaperStateSyncCommand;
              Type = "oneshot";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };

        path = {
          "variety-wallpaper-updated" = {
            Unit = {
              Description = "Watch Variety wallpaper pointer";
              After = [ rcloneDropboxPrivateService ];
              Wants = [
                "variety-wallpaper-updated.service"
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

      wallust = {
        service = {
          wallust = {
            Unit = {
              Description = "Generate Wallust palette from current wallpaper";
              After = [ "variety-wallpaper-updated.service" ];
              Wants = [ "variety-wallpaper-updated.service" ];
            };
            Service = {
              ExecStart = runWallustFromCurrentWallpaperCommand;
              Type = "oneshot";
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
          };
        };

        path = {
          wallust = {
            Unit = {
              Description = "Watch canonical wallpaper state for Wallust";
              Wants = [ "wallust.service" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Path = {
              PathModified = currentWallpaperStateFile;
            };
          };
        };
      };

      noctaliaWallpaper = {
        service = {
          "noctalia-wallpaper" = {
            Unit = {
              Description = "Sync current wallpaper to Noctalia";
              After = [ "variety-wallpaper-updated.service" ];
              Wants = [ "variety-wallpaper-updated.service" ];
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
          "noctalia-wallpaper" = {
            Unit = {
              Description = "Watch canonical wallpaper state for Noctalia";
              Wants = [ "noctalia-wallpaper.service" ];
            };
            Install = {
              WantedBy = [ "graphical-session.target" ];
            };
            Path = {
              PathModified = currentWallpaperStateFile;
            };
          };
        };
      };
    };
    description = "Systemd services for wallpaper state.";
  };

  config = {
    systemd.user.services = lib.mkMerge [
      (lib.mkIf config.customPackages.gui.enable (
        config.customServices.wallpaper.varietyWallpaper.service or { }
      ))
      (lib.mkIf config.customPackages.gui.enable (config.customServices.wallpaper.wallust.service or { }))
      (lib.mkIf config.customPackages.gui.enable (
        config.customServices.wallpaper.noctaliaWallpaper.service or { }
      ))
    ];

    systemd.user.paths = lib.mkMerge [
      (lib.mkIf config.customPackages.gui.enable (
        config.customServices.wallpaper.varietyWallpaper.path or { }
      ))
      (lib.mkIf config.customPackages.gui.enable (config.customServices.wallpaper.wallust.path or { }))
      (lib.mkIf config.customPackages.gui.enable (
        config.customServices.wallpaper.noctaliaWallpaper.path or { }
      ))
    ];
  };
}
