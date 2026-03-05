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
  niriFocusGradientFile = "${config.xdg.configHome}/niri/generated/wallust-focus-ring.kdl";

  noctaliaWallpaperSyncScript = pkgs.writeShellScript "noctalia-sync-variety-wallpaper" ''
    set -eu

    if ! ${pkgs.procps}/bin/pgrep -x niri >/dev/null; then
      exit 0
    fi

    if [ ! -r '${varietyWallpaperPointerFile}' ]; then
      exit 0
    fi

    IFS= read -r wallpaper_path < '${varietyWallpaperPointerFile}' || true
    if [ -z "''${wallpaper_path:-}" ] || [ ! -r "$wallpaper_path" ]; then
      exit 0
    fi

    ${pkgs.noctalia-shell}/bin/noctalia-shell ipc --newest call wallpaper set "$wallpaper_path" all >/dev/null 2>&1 || true
  '';

  niriSessionExecCondition = "${pkgs.bash}/bin/bash -lc ${lib.escapeShellArg "${pkgs.coreutils}/bin/printenv XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qi niri"}";
  lockScreenCommand = "${pkgs.noctalia-shell}/bin/noctalia-shell ipc --newest call lockScreen lock";
  niriFocusGradientSyncScript = pkgs.writeShellScript "sync-niri-focus-gradient" ''
    set -eu

    wallust_cache_dir="${config.xdg.cacheHome}/wallust"
    noctalia_colors_file="${config.xdg.configHome}/noctalia/colors.json"
    target_file="${niriFocusGradientFile}"

    from_color=""
    to_color=""
    latest_dir=""

    if [ -d "$wallust_cache_dir" ]; then
      for dir in "$wallust_cache_dir"/*_1.7; do
        [ -d "$dir" ] || continue
        if [ -z "$latest_dir" ] || [ "$dir" -nt "$latest_dir" ]; then
          latest_dir="$dir"
        fi
      done

      if [ -n "$latest_dir" ]; then
        for candidate in "$latest_dir"/*; do
          [ -f "$candidate" ] || continue
          if ${pkgs.jq}/bin/jq -e '.color12 and .color10' "$candidate" >/dev/null 2>&1; then
            from_color="$(${pkgs.jq}/bin/jq -r '.color12 // empty' "$candidate")"
            to_color="$(${pkgs.jq}/bin/jq -r '.color10 // empty' "$candidate")"
            break
          fi
        done
      fi
    fi

    if [ -z "$from_color" ] || [ -z "$to_color" ]; then
      if [ -r "$noctalia_colors_file" ]; then
        from_color="$(${pkgs.jq}/bin/jq -r '.mPrimary // empty' "$noctalia_colors_file")"
        to_color="$(${pkgs.jq}/bin/jq -r '.mHover // empty' "$noctalia_colors_file")"
      fi
    fi

    [ -n "$from_color" ] || exit 0
    [ -n "$to_color" ] || exit 0

    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$target_file")"
    tmp_file="$target_file.tmp"
    ${pkgs.coreutils}/bin/printf '%s\n' \
      'layout {' \
      '    focus-ring {' \
      "        active-gradient from=\"$from_color\" to=\"$to_color\" angle=45" \
      '    }' \
      '}' > "$tmp_file"
    ${pkgs.coreutils}/bin/mv "$tmp_file" "$target_file"

    if ${pkgs.procps}/bin/pgrep -x niri >/dev/null 2>&1; then
      ${pkgs.niri}/bin/niri msg action load-config-file >/dev/null 2>&1 || true
    fi
  '';

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
                ExecStartPost = "${niriFocusGradientSyncScript}";
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
                ExecStart = "${noctaliaWallpaperSyncScript}";
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

    systemd = {
      user = {
        startServices = true;

        services = lib.mkMerge [
          config.customServices.rclone
          config.customServices.variety
          config.customServices.wallust.service
          config.customServices.noctaliaWallpaper.service
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
