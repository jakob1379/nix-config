{
  pkgs,
  ...
}:

{
  # System-specific overrides for Raspberry Pi
  customPackages = {
    enableGui = false;
  };

  programs.firefox.enable = pkgs.lib.mkForce false;

  customServices = {
    rclone = { };
    wallust = { };
  };

  services = {
    unclutter.enable = pkgs.lib.mkForce false;
    easyeffects.enable = pkgs.lib.mkForce false;
    mpris-proxy.enable = pkgs.lib.mkForce false;
  };
}
