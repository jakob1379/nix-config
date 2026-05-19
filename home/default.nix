{
  lib,
  homeModules,
}:
let
  inherit (lib) mkHomeConfig;
  baseModules = [
    homeModules.waytorandr
    homeModules.common
    homeModules.packages
    homeModules.dotfiles
    homeModules.git-ssh
    homeModules.shell-cli
    homeModules.dev-ai
    homeModules.desktop-apps
    homeModules.home-storage
    homeModules.home-wallpaper
    homeModules.home-niri-desktop
    homeModules.home-session-services
  ];
  mkHome = args: mkHomeConfig ({ inherit lib baseModules; } // args);
in
{
  "jsg@DESKTOP-IQEP2ED" = mkHome {
    system = "x86_64-linux";
    username = "jsg";
    homeDirectory = "/home/jsg";
    extraModules = [ homeModules.host-seeq ];
  };

  "pi@raspberrypi" = mkHome {
    system = "aarch64-linux";
    username = "pi";
    homeDirectory = "/home/pi";
    extraModules = [ homeModules.host-pi ];
  };

  "jga@yoga" = mkHome {
    system = "x86_64-linux";
    username = "jga";
    homeDirectory = "/home/jga";
    extraModules = [ homeModules.host-yoga ];
  };

  "jsg@amd" = mkHome {
    system = "x86_64-linux";
    username = "jsg";
    homeDirectory = "/home/jsg";
    extraModules = [ homeModules.host-amd ];
  };

}
