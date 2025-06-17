{ config, lib, pkgs, ... }:

let
  # Packages to exclude on the Raspberry Pi to save space/resources
  packagesToExclude = with pkgs; [
    texlive.combined.scheme-full
    texlivePackages.fontawesome5
    # The following are large GUI apps not needed on a server
    brave
    onlyoffice-bin
    slack
    spotify
    thunderbird
    vlc
  ];
in {
  # System-specific overrides for Raspberry Pi
  customPackages = {
    gui = []; # Disable GUI packages
    exclude = packagesToExclude;
  };

  programs.firefox.enable = false;

  customServices = {
    rclone = {};
    pywal = {};
    pywalPath = {};
  };

  services.unclutter.enable = false;
  services.easyeffects.enable = false;
  services.mpris-proxy.enable = false;

  # Override SSH config for Pi
  home.file.".ssh/config".text = ''
    Host *
      AddKeysToAgent yes
  '';
}
