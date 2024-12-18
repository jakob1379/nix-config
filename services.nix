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
      mountPath ? "/home/${config.home.username}/${name}",
      remotePath ? "/",
    }:
    {
      Unit = {
        Description = "Rclone mount service for ${name}";
      };

      Service = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
        ExecStart = ''
            ${pkgs.rclone}/bin/rclone mount \
              --config /home/${config.home.username}/.config/rclone/rclone.conf \
              --allow-other \
              --attr-timeout 1h \
              --buffer-size=0 \
              --dir-cache-time 3h0m0s \
              --poll-interval 30s \
              --use-server-modtime \
              --vfs-cache-mode full \
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

  services = {
    emacs.defaultEditor = true;
    unclutter = {
      enable = true;
      timeout = 5;
    };
    ssh-agent.enable = true;
    easyeffects.enable = true;
    mpris-proxy.enable = true;
    # random-background = {
    #   enable = true;
    #   display = "fill";
    #   imageDirectory = "%h/dropbox-private/Andet/Favorites";
    # };
  };

  systemd.user.startServices = true;
  systemd.user.services = {
    # Create the rclone mount services by calling the function with the desired parameters using named arguments
    rclone-mount-dropbox-private = createRcloneMountService {
      name = "dropbox-private";
    };
    rclone-mount-onedrive-ku-crypt = createRcloneMountService {
      name = "onedrive-ku-crypt";
    };
    rclone-mount-onedrive-ku = createRcloneMountService {
      name = "onedrive-ku";
    };
    # rclone-mount-gdrive-private = createRcloneMountService {
    #   name = "gdrive-private";
    #   remote = "gdrive-private";
    # };
  };

}
