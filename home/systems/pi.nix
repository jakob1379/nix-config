{
  pkgs,
  ...
}:

{
  # System-specific overrides for Raspberry Pi
  customPackages.gui.enable = false;

  programs.firefox.enable = pkgs.lib.mkForce false;

  services = {
    unclutter.enable = pkgs.lib.mkForce false;
    easyeffects.enable = pkgs.lib.mkForce false;
    mpris-proxy.enable = pkgs.lib.mkForce false;
  };
}
