{
  config,
  inputs,
  pkgs,
  lib,
  system,
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
  noctaliaPackage = inputs.noctalia.packages.${system}.default;

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

  varietyWallpaperStateSyncScript = pkgs.writeShellApplication {
    name = "sync-variety-wallpaper-state";
    runtimeInputs = [
      pkgs.coreutils
      noctaliaPackage
      pkgs.wallust
    ];
    text = builtins.readFile ../../scripts/wallpaper/sync-variety-wallust-terminal-colors.sh;
  };

  varietyWallpaperStateSyncCommand =
    "${varietyWallpaperStateSyncScript}/bin/sync-variety-wallpaper-state "
    + lib.escapeShellArg "${pkgs.variety}/bin/variety";

  niriWindowBorderRulesWatchCommand =
    "${niriWindowBorderRulesWatchScript}/bin/watch-niri-window-border-rules "
    + "${lib.escapeShellArg "${niriWindowBorderRulesSyncScript}/bin/sync-niri-window-border-rules"} "
    + "${lib.escapeShellArg niriWindowBorderRulesFile}";

in
{
  config =
    let
      coreServices = {
        emacs = {
          package = pkgs.emacs31-pgtk;
          startWithUserSession = false;
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
            (lib.mkIf config.customPackages.gui.enable {
              rclone-mount-dropbox-private = createRcloneMountService { name = "dropbox-private"; };

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

              "variety-wallpaper-sync" = {
                Unit = {
                  Description = "Sync Noctalia and terminal colors from Variety wallpaper";
                  After = [ rcloneDropboxPrivateService ];
                  Wants = [ rcloneDropboxPrivateService ];
                  Requires = [ rcloneDropboxPrivateService ];
                };
                Service = {
                  ExecStart = varietyWallpaperStateSyncCommand;
                  TimeoutStartSec = 60;
                  Type = "oneshot";
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };

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
            })
            (lib.mkIf config.services.swayidle.enable {
              swayidle.Service.ExecCondition = niriSessionExecCondition;
            })
          ];

          paths = lib.mkMerge [
            (lib.mkIf config.customPackages.gui.enable {
              "variety-wallpaper-sync" = {
                Unit = {
                  Description = "Watch Variety wallpaper pointer for Noctalia and terminal colors";
                  After = [ rcloneDropboxPrivateService ];
                  Wants = [
                    "variety-wallpaper-sync.service"
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
            })
          ];
        };
      };

      services = coreServices // lib.optionalAttrs config.customPackages.gui.enable guiServices;
    };
}
