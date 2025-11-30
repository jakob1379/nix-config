{
  config,
  pkgs,
  lib,
  ...
}:




      pywal = lib.mkOption {
        type = lib.types.attrs;
        default = {
          pywal-apply-variety = {
            Unit = {
              Description = "Apply pywal theme based on Variety wallpaper";
              After = [
                "graphical-session.target"
                "network-online.target"
                
              ];
              Wants = [
                "network-online.target"
                
              ];
              Requires = [  ];
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
                
              ];
              Wants = [
                "network-online.target"
                
              ];
              Requires = [  ];
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
              After = [  ];
              Wants = [
                "pywal-apply-variety.service"
                
              ];
              Requires = [  ];
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

      ssh-agent.enable = true;
      easyeffects.enable = true;
      mpris-proxy.enable = true;
      home-manager.autoExpire.enable = true;
    };
  };
}
