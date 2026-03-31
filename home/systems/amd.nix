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
    core.packages = lib.mkForce (
      with pkgs;
      [
        (btop.override {
          rocmSupport = true;
        })
        git-filter-repo
        busybox
        dconf
        duf
        entr
        gdu
        gitflow
        gitleaks
        glib
        gnumake
        unixtools.ping
        hyperfine
        imagemagick
        isd
        libqalculate
        libsecret
        nix-output-monitor
        nix-prefetch-github
        nix-search-cli
        onefetch
        python3Packages.keyring
        rename
        silver-searcher
        speedtest-go
        tldr
        unar
        yq-go
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
