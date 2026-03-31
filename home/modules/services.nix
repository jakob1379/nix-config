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

  varietyWallpaperPointerFile = "${config.xdg.configHome}/variety/wallpaper/wallpaper.jpg.txt";
  wallpaperStateDir = "${config.xdg.stateHome}/wallpaper";
  currentWallpaperStateFile = "${wallpaperStateDir}/current-wallpaper";
  wallustPaletteStateFile = "${wallpaperStateDir}/wallust-palette.json";
  niriGeneratedFilesDir = "${config.xdg.configHome}/niri/generated";
  niriFocusGradientFile = "${niriGeneratedFilesDir}/wallust-focus-ring.kdl";
  niriWindowBorderRulesFile = "${niriGeneratedFilesDir}/window-border-rules.kdl";
  vicinaeThemesDir = "${config.xdg.dataHome}/vicinae/themes";
  vicinaeWallustDarkThemeFile = "${vicinaeThemesDir}/wallust-dark.toml";
  vicinaeWallustLightThemeFile = "${vicinaeThemesDir}/wallust-light.toml";

  noctaliaWallpaperSyncScript = pkgs.writeShellApplication {
    name = "sync-noctalia-wallpaper";
    runtimeInputs = [
      pkgs.noctalia-shell
      pkgs.procps
      pkgs.coreutils
    ];
    text = builtins.readFile ../../dotfiles/niri/scripts/sync-noctalia-wallpaper.sh;
  };

  currentWallpaperStateSyncScript = pkgs.writeShellApplication {
    name = "update-current-wallpaper-state";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ../../dotfiles/wallpaper/scripts/update-current-wallpaper-state.sh;
  };

  wallustPaletteStateSyncScript = pkgs.writeShellApplication {
    name = "update-wallust-palette-state";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ../../dotfiles/wallpaper/scripts/update-wallust-palette-state.sh;
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
    text = builtins.readFile ../../dotfiles/wallpaper/scripts/sync-vicinae-theme.sh;
  };

  noctaliaWallpaperSyncCommand =
    "${noctaliaWallpaperSyncScript}/bin/sync-noctalia-wallpaper "
    + lib.escapeShellArg currentWallpaperStateFile;
  niriFocusGradientSyncCommand =
    "${niriFocusGradientSyncScript}/bin/sync-niri-focus-gradient "
    + "${lib.escapeShellArg wallustPaletteStateFile} "
    + "${lib.escapeShellArg "${config.xdg.configHome}/noctalia/colors.json"} "
    + "${lib.escapeShellArg niriFocusGradientFile}";
  vicinaeThemeSyncCommand =
    "${vicinaeThemeSyncScript}/bin/sync-vicinae-theme "
    + "${lib.escapeShellArg wallustPaletteStateFile} "
    + "${lib.escapeShellArg vicinaeWallustDarkThemeFile} "
    + "${lib.escapeShellArg vicinaeWallustLightThemeFile}";
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
    text = builtins.readFile ../../dotfiles/wallpaper/scripts/run-wallust-from-current-wallpaper.sh;
  };
  runWallustFromCurrentWallpaperCommand =
    "${runWallustFromCurrentWallpaperScript}/bin/run-wallust-from-current-wallpaper "
    + "${lib.escapeShellArg currentWallpaperStateFile} "
    + "${lib.escapeShellArg "${config.xdg.cacheHome}/wallust"} "
    + lib.escapeShellArg wallustPaletteStateFile;
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
              "variety-wallpaper-updated" = {
                Unit = {
                  Description = "Resolve current wallpaper from Variety";
                  StartLimitIntervalSec = 0;
                  After = [ "rclone-mount-dropbox-private.service" ];
                  Wants = [ "rclone-mount-dropbox-private.service" ];
                  Requires = [ "rclone-mount-dropbox-private.service" ];
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
                  After = [ "rclone-mount-dropbox-private.service" ];
                  Wants = [
                    "variety-wallpaper-updated.service"
                    "rclone-mount-dropbox-private.service"
                  ];
                  Requires = [ "rclone-mount-dropbox-private.service" ];
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

      desktop = lib.mkOption {
        type = lib.types.attrs;
        default = {
          niriFocusGradient = {
            service = {
              "niri-focus-gradient" = {
                Unit = {
                  Description = "Sync Niri focus gradient from Wallust palette";
                  After = [ "wallust.service" ];
                  Wants = [ "wallust.service" ];
                };
                Service = {
                  ExecStart = niriFocusGradientSyncCommand;
                  Type = "oneshot";
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };
            };

            path = {
              "niri-focus-gradient" = {
                Unit = {
                  Description = "Watch Wallust palette for Niri focus gradient sync";
                  Wants = [ "niri-focus-gradient.service" ];
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
                Path = {
                  PathModified = wallustPaletteStateFile;
                };
              };
            };
          };

          vicinaeTheme = {
            service = {
              "vicinae-theme" = {
                Unit = {
                  Description = "Sync Vicinae themes from Wallust palette";
                  After = [ "wallust.service" ];
                  Wants = [ "wallust.service" ];
                };
                Service = {
                  ExecStart = vicinaeThemeSyncCommand;
                  Type = "oneshot";
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
              };
            };

            path = {
              "vicinae-theme" = {
                Unit = {
                  Description = "Watch Wallust palette for Vicinae theme sync";
                  Wants = [ "vicinae-theme.service" ];
                };
                Install = {
                  WantedBy = [ "graphical-session.target" ];
                };
                Path = {
                  PathModified = wallustPaletteStateFile;
                };
              };
            };
          };

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

        ssh-agent = {
          enable = true;
          enableBashIntegration = true;
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

        swayidle = {
          inherit (config.customPackages.gui) enable;
          package = pkgs.swayidle;
          systemdTargets = [ "graphical-session.target" ];
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
      };
    in
    {
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
            (lib.mkIf config.customPackages.gui.enable (cfg.storage.rclone.service or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.varietyWallpaper.service or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.wallust.service or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.noctaliaWallpaper.service or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.desktop.niriFocusGradient.service or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.desktop.vicinaeTheme.service or { }))
            (lib.mkIf config.customPackages.gui.enable cfg.desktop.niriWindowBorders)
            (lib.mkIf config.services.swayidle.enable {
              swayidle.Service.ExecCondition = niriSessionExecCondition;
            })
          ];

          paths = lib.mkMerge [
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.varietyWallpaper.path or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.wallust.path or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.wallpaper.noctaliaWallpaper.path or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.desktop.niriFocusGradient.path or { }))
            (lib.mkIf config.customPackages.gui.enable (cfg.desktop.vicinaeTheme.path or { }))
          ];
        };
      };

      services = coreServices // lib.optionalAttrs config.customPackages.gui.enable guiServices;
    };
}
