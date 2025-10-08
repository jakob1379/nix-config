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
      remote,
      mountPath ? "/home/jga/${name}",
      remotePath ? "/",
    }:
    {
      description = "Rclone mount service for ${name}";
      after = [ "network-online.target" ];
      restartIfChanged = true;
      enable = true;
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPath}";
        ExecStart = "${pkgs.rclone}/bin/rclone mount --config /home/jga/.config/rclone/rclone.conf --vfs-fast-fingerprint --vfs-cache-mode full ${remote}:${remotePath} ${mountPath}";
        Type = "notify";
        Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
      };
    };
in
{
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "yoga";

  i18n.defaultLocale = "da_DK.UTF-8";

  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [ ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:45:0:0";
    };
    package = config.boot.kernelPackages.nvidiaPackages.beta;
  };

  users.users.jga = lib.mkForce (
    config.users.users.jga
    // {
      extraGroups = config.users.users.jga.extraGroups ++ [ "netbird-jgalabs" ];
    }
  );

  systemd.user.services = {
    rclone-mount-dropbox-private = createRcloneMountService {
      name = "dropbox-private";
      remote = "dropbox-private";
    };
  };

  system.stateVersion = config.system.stateVersion;
}
