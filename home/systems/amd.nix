{
  pkgs,
  lib,
  ...
}:

{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customPackages = {
    enableGui = lib.mkForce true;
    exclude = with pkgs; [ btop ];
    extra = with pkgs; [
      (btop.override {
        rocmSupport = true;
      })
      clockify
      adw-gtk3
      glab
      # teams-for-linux
      kdePackages.qt6ct
      libsForQt5.qt5ct
      nwg-look
      codex
    ];
  };

  services.tailscale-systray.enable = true;

  customDotfiles = {
    enableMediaControl = true;
  };
}
