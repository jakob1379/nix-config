{ pkgs, ... }:

{
  security.polkit.enable = true;
  security.sudo.package = pkgs.sudo.override { withInsults = true; };

  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
  };
}
