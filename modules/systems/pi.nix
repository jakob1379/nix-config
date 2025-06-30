{
  pkgs,
  ...
}:

let
  # Packages to exclude on the Raspberry Pi to save space/resources
  packagesToExclude = with pkgs; [
    # The following are large GUI apps not needed on a server
    brave
    onlyoffice-bin
    slack
    spotify
    thunderbird
    vlc
  ];
in
{
  # System-specific overrides for Raspberry Pi
  customPackages = {
    enableGui = false; # Disable GUI packages
    exclude = packagesToExclude;
  };

  programs.firefox.enable = false;

  customServices = {
    rclone = { };
    pywal = { };
    pywalPath = { };
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
