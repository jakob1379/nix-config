{ pkgs, ... }:

{
  # Disable screenreader.
  services.orca.enable = false;

  services.xserver.enable = true;
  services.displayManager = {
    sddm.enable = true;
    sddm.wayland.enable = true;
    sddm.theme = "breeze";
    defaultSession = "niri";
  };

  qt.enable = true;
  services.desktopManager.plasma6 = {
    enable = true;
    enableQt5Integration = true;
  };
  environment.plasma6.excludePackages = with pkgs.kdePackages; [ kate ];

  environment.etc."environment.d/desktop-environment.conf".text = ''
    [Environment]
    DESKTOP_SESSION=$XDG_SESSION_DESKTOP
  '';

  environment.variables.KWIN_DRM_PREFER_COLOR_DEPTH = "24";

  services.xserver.videoDrivers = [
    "modesetting"
  ];

  systemd.services.displaylink = {
    enable = true;
    description = "DisplayLink Manager";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udevd.service" ];
    requires = [ "systemd-udevd.service" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      Restart = "on-failure";
      RestartSec = 5;
      User = "root";
      Group = "root";
    };
  };

  services.iio-niri.enable = true;
  programs.niri = {
    enable = true;
    useNautilus = false;
  };
}
