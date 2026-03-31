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
          cudaSupport = true;
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
  };

  customDotfiles = {
    enableMediaControl = true;
  };
}
