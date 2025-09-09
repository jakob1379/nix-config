{ lib }:
let
  inherit (lib) mkHomeConfig;
in {
  "pi@raspberrypi" = mkHomeConfig {
    system = "aarch64-linux";
    username = "pi";
    homeDirectory = "/home/pi";
    extraModules = [ ../modules/systems/pi.nix ];
  };

  "fuzie@Fuzie-pc" = mkHomeConfig {
    system = "x86_64-linux";
    username = "fuzie";
    homeDirectory = "/home/fuzie";
    extraModules = [ ../modules/systems/wsl.nix ];
  };

  "jga@yoga" = mkHomeConfig {
    system = "x86_64-linux";
    username = "jga";
    homeDirectory = "/home/jga";
    extraModules = [ ../modules/systems/yoga.nix ];
  };

  "jga@ku" = mkHomeConfig {
    system = "x86_64-linux";
    username = "jga";
    homeDirectory = "/home/jga";
    extraModules = [ ../modules/systems/ucph.nix ];
  };

  "jga@ubuntu" = mkHomeConfig {
    system = "x86_64-linux";
    username = "jga";
    homeDirectory = "/home/jga";
    extraModules = [ ../modules/systems/ubuntu.nix ];
  };
}
