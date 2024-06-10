{ config, pkgs, lib, ... }:
let
  createRcloneMountService = { name, remote, mountPath ? "/home/${config.home.username}/${name}", remotePath ? "/" }: {
    Unit = {
      Description = "Rclone mount service for ${name}";
      After = [ "network-online.target" ];
    };

    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
      ExecStart = "${pkgs.rclone}/bin/rclone mount --config /home/${config.home.username}/.config/rclone/rclone.conf --vfs-fast-fingerprint --vfs-cache-mode full ${remote}:${remotePath} ${mountPath}";
      Type = "simple";
      Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
    };

    Install = {
      WantedBy = [ "default.target" "network-online.target" ];
    };
  };

in
{

  home.packages = with pkgs; [
    rclone
  ];

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
    rclone-mount-dropbox-private = createRcloneMountService {
      name = "dropbox-private";
      remote = "dropbox-private";
    };
    rclone-mount-gdrive-private = createRcloneMountService {
      name = "gdrive-private";
      remote = "gdrive-private";
    };
  };

}
