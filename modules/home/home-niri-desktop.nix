{
  config,
  pkgs,
  lib,
  ...
}:

let
  wallpaperStateDir = "${config.xdg.stateHome}/wallpaper";
  wallustPaletteStateFile = "${wallpaperStateDir}/wallust-palette.json";
  niriGeneratedFilesDir = "${config.xdg.configHome}/niri/generated";
  niriFocusGradientFile = "${niriGeneratedFilesDir}/wallust-focus-ring.kdl";
  niriWindowBorderRulesFile = "${niriGeneratedFilesDir}/window-border-rules.kdl";
  vicinaeThemesDir = "${config.xdg.dataHome}/vicinae/themes";
  vicinaeWallustDarkThemeFile = "${vicinaeThemesDir}/wallust-dark.toml";
  vicinaeWallustLightThemeFile = "${vicinaeThemesDir}/wallust-light.toml";

  niriSessionExecCondition = "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg "${pkgs.coreutils}/bin/printenv XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qi niri"}";

  niriFocusGradientSyncScript = pkgs.writeShellApplication {
    name = "sync-niri-focus-gradient";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.niri
      pkgs.procps
    ];
    text = builtins.readFile ../../scripts/niri/sync-focus-gradient.sh;
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

  vicinaeThemeSyncScript = pkgs.writeShellApplication {
    name = "sync-vicinae-theme";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = builtins.readFile ../../scripts/wallpaper/sync-vicinae-theme.sh;
  };

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
  niriWindowBorderRulesWatchCommand =
    "${niriWindowBorderRulesWatchScript}/bin/watch-niri-window-border-rules "
    + "${lib.escapeShellArg "${niriWindowBorderRulesSyncScript}/bin/sync-niri-window-border-rules"} "
    + "${lib.escapeShellArg niriWindowBorderRulesFile}";
in
{
  options.customServices.desktop = lib.mkOption {
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

    systemd.user.services = lib.mkMerge [
      (lib.mkIf config.customPackages.gui.enable (
        config.customServices.desktop.niriFocusGradient.service or { }
      ))
      (lib.mkIf config.customPackages.gui.enable (
        config.customServices.desktop.vicinaeTheme.service or { }
      ))
      (lib.mkIf config.customPackages.gui.enable config.customServices.desktop.niriWindowBorders)
      (lib.mkIf config.services.swayidle.enable {
        swayidle.Service.ExecCondition = niriSessionExecCondition;
      })
    ];

    systemd.user.paths = lib.mkMerge [
      (lib.mkIf config.customPackages.gui.enable (
        config.customServices.desktop.niriFocusGradient.path or { }
      ))
      (lib.mkIf config.customPackages.gui.enable (config.customServices.desktop.vicinaeTheme.path or { }))
    ];
  };
}
