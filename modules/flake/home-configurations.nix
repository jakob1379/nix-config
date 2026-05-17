{ config, ... }:

{
  flake.homeConfigurations = import ../../home {
    lib = config.flake.lib;
    homeModules = config.flake.modules.homeManager;
  };
}
