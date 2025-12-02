{ lib }:
let
  inherit (lib) mkHomeConfig;
in
{
  "pi@raspberrypi" = mkHomeConfig {
    system = "aarch64-linux";
    username = "pi";
    homeDirectory = "/home/pi";
    extraModules = [ ../modules/systems/pi.nix ];
    inherit lib;
  };

  "fuzie@Fuzie-pc" = mkHomeConfig {
    system = "x86_64-linux";
    username = "fuzie";
    homeDirectory = "/home/fuzie";
    extraModules = [ ../modules/systems/wsl.nix ];
    inherit lib;
  };

  "jga@yoga" = mkHomeConfig {
    system = "x86_64-linux";
    username = "jga";
    homeDirectory = "/home/jga";
    extraModules = [ ../modules/systems/yoga.nix ];
    inherit lib;
  };

  "jsg@amd" = mkHomeConfig {
    system = "x86_64-linux";
    username = "jsg";
    homeDirectory = "/home/jsg";
    extraModules = [ ../modules/systems/amd.nix ];
    inherit lib;
  };

}
