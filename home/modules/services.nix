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
    text = ''
      set -eu

      pointer_file="$1"
      target_file="$2"
      attempts=0

      ${pkgs.coreutils}/bin/sleep 3

      while [ "$attempts" -lt 5 ]; do
        wallpaper_path=""

        if [ -r "$pointer_file" ]; then
          wallpaper_path="$(< "$pointer_file")"
        fi

        if [ -n "''${wallpaper_path:-}" ] && [ -r "$wallpaper_path" ]; then
          current_wallpaper=""

          if [ -r "$target_file" ]; then
            current_wallpaper="$(< "$target_file")"
          fi

          if [ "$current_wallpaper" = "$wallpaper_path" ]; then
            exit 0
          fi

          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target_file")"
          tmp_file="$target_file.tmp"
          ${pkgs.coreutils}/bin/printf '%s\n' "$wallpaper_path" > "$tmp_file"
          ${pkgs.coreutils}/bin/mv "$tmp_file" "$target_file"
          exit 0
        fi

        attempts=$((attempts + 1))
        ${pkgs.coreutils}/bin/sleep 1
      done

      exit 1
    '';
  };

  wallustPaletteStateSyncScript = pkgs.writeShellApplication {
    name = "update-wallust-palette-state";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      set -eu

      wallust_cache_dir="$1"
      target_file="$2"
      latest_dir=""
      palette_file=""

      if [ -d "$wallust_cache_dir" ]; then
        for dir in "$wallust_cache_dir"/*_1.7; do
          [ -d "$dir" ] || continue
          if [ -z "$latest_dir" ] || [ "$dir" -nt "$latest_dir" ]; then
            latest_dir="$dir"
          fi
        done
      fi

      if [ -n "$latest_dir" ]; then
        for candidate in "$latest_dir"/*; do
          [ -f "$candidate" ] || continue
          if ${pkgs.jq}/bin/jq -e '.background and .foreground and .color0 and .color7 and .color8 and .color9 and .color10 and .color11 and .color12 and .color13 and .color14' "$candidate" >/dev/null 2>&1; then
            palette_file="$candidate"
            break
          fi
        done
      fi

      [ -n "$palette_file" ] || exit 1

      ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target_file")"
      tmp_file="$target_file.tmp"
      ${pkgs.coreutils}/bin/cp "$palette_file" "$tmp_file"
      ${pkgs.coreutils}/bin/mv "$tmp_file" "$target_file"
    '';
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
  wallustScript = pkgs.writeShellApplication {
    name = "run-wallust-from-current-wallpaper";
    runtimeInputs = [
      pkgs.wallust
      wallustPaletteStateSyncScript
    ];
    text = ''
      set -eu

      if [ ! -r ${lib.escapeShellArg currentWallpaperStateFile} ]; then
        exit 0
      fi

      IFS= read -r wallpaper_path < ${lib.escapeShellArg currentWallpaperStateFile} || exit 0
      if [ -z "$wallpaper_path" ] || [ ! -r "$wallpaper_path" ]; then
        exit 0
      fi

      wallust run -k "$wallpaper_path"
      update-wallust-palette-state \
        ${lib.escapeShellArg "${config.xdg.cacheHome}/wallust"} \
        ${lib.escapeShellArg wallustPaletteStateFile}
    '';
  };
  shikaneDefaultWatchScript = pkgs.writeShellApplication {
    name = "watch-shikane-default";
    runtimeInputs = [
      pkgs.jq
      pkgs.niri
      pkgs.shikane
    ];
    text = ''
      set -eu

      last_output_hash="$(shikanectl __current-output-hash 2>/dev/null || true)"
      shikanectl __maybe-switch-default >/dev/null 2>&1 || true

      niri msg --json event-stream | while IFS= read -r event_line; do
        [ -n "$event_line" ] || continue

        if ! printf '%s\n' "$event_line" | jq -e 'has("WorkspacesChanged")' >/dev/null 2>&1; then
          continue
        fi

        current_output_hash="$(shikanectl __current-output-hash 2>/dev/null || true)"
        if [ -z "$current_output_hash" ] || [ "$current_output_hash" = "$last_output_hash" ]; then
          continue
        fi

        last_output_hash="$current_output_hash"
        shikanectl __maybe-switch-default >/dev/null 2>&1 || true
      done
    '';
  };
  shikaneDefaultWatchCommand = "${shikaneDefaultWatchScript}/bin/watch-shikane-default";
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
                  ExecStart = "${wallustScript}/bin/run-wallust-from-current-wallpaper";
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

          shikaneDefault = {
            shikanectl-default-watcher = {
              Unit = {
                Description = "Reapply shikanectl default profiles for current outputs";
                After = [
                  "graphical-session.target"
                  "shikane.service"
                ];
                Wants = [ "shikane.service" ];
              };
              Install = {
                WantedBy = [ "graphical-session.target" ];
              };
              Service = {
                ExecCondition = niriSessionExecCondition;
                ExecStart = shikaneDefaultWatchCommand;
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
            (lib.mkIf (
              config.customPackages.gui.enable && config.services.shikane.enable
            ) cfg.desktop.shikaneDefault)
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
