{ ... }:

{
  networking.networkmanager.enable = true;
  services.resolved.enable = true;

  services.tailscale.enable = true;
  services.netbird = {
    ui.enable = true;
    enable = true;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  networking.firewall = {
    enable = true;
  };
}
