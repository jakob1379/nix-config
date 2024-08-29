{ config, pkgs, lib, ... }:
let
  createNativeRcloneMountService = { name, remote, mountPath ? "/home/${config.home.username}/${name}", remotePath ? "/" }: {
    Unit = {
      Description = "Rclone mount service for ${name}";
    };

    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
      ExecStart = ''
        rclone mount \
          --config /home/${config.home.username}/.config/rclone/rclone.conf \
          --vfs-fast-fingerprint \
          --vfs-cache-mode full \
          --allow-other \
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

  # createRcloneMountService = { name, remote, mountPath ? "/home/${config.home.username}/${name}", remotePath ? "/" }: {
  #   Unit = {
  #     Description = "Rclone mount service for ${name}";
  #     After = [ "network-online.target" ];
  #     Requires = [ "network-online.target" ];
  #     After = [ "systemd-networkd-wait-online.service" ];  # or "systemd-networkd-wait-online.service"
  #     Wants = [ "systemd-networkd-wait-online.service" ];   # or "systemd-networkd-wait-online.service"
  #   };

  #   Service = {
  #     ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
  #     ExecStart = ''
  #       ${pkgs.rclone}/bin/rclone mount \
  #         --config /home/${config.home.username}/.config/rclone/rclone.conf \
  #         --vfs-fast-fingerprint \
  #         --vfs-cache-mode full \
  #         --allow-other \
  #         ${remote}:${remotePath} ${mountPath}
  #     #   '';
  #     ExecStop = "${pkgs.fuse3}/fusermount -u ${mountPath}";
  #     Type = "notify";
  #     Restart = "on-failure";
  #     RestartSec = "10s";
  #     Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
  #   };

  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

in
{

  services = {
    copyq.enable = true;
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
    rclone-mount-dropbox-private = createNativeRcloneMountService {
      name = "dropbox-private";
      remote = "dropbox-private";
    };
    # rclone-mount-gdrive-private = createNativeRcloneMountService {
    #   name = "gdrive-private";
    #   remote = "gdrive-private";
    # };
  };

}
