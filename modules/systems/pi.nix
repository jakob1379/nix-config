{
  pkgs,
  ...
}:

let
  # Packages to exclude on the Raspberry Pi to save space/resources
  packagesToExclude = with pkgs; [
  ];
in
{
  # System-specific overrides for Raspberry Pi
  customPackages = {
    enableGui = false;
    exclude = packagesToExclude;
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
