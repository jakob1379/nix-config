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
    gui.enable = lib.mkForce true;
    exclude = with pkgs; [ btop ];
    extra = lib.mkAfter (
      with pkgs;
      [
        (btop.override {
          rocmSupport = true;
        })
      ]
    );
    gui.packages = lib.mkAfter (
      with pkgs;
      [
        clockify
        adw-gtk3
        glab
        # teams-for-linux
        kdePackages.qt6ct
        libsForQt5.qt5ct
        nwg-look
        codex
      ]
    );
  };

  services.tailscale-systray.enable = true;

  customDotfiles = {
    enableMediaControl = true;
  };
}
