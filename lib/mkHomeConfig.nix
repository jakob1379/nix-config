{ inputs, ... }:

{
  system,
  username,
  homeDirectory,
  extraModules ? [ ],
}:

inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = inputs.nixpkgs.legacyPackages.${system};
  modules =
    [
      # All systems import the common base configuration
      ../modules/systems/common.nix

      # Set user and home from arguments
      {
        home.username = username;
        home.homeDirectory = homeDirectory;
      }
    ]
    # And add their system-specific modules
    ++ extraModules;
  extraSpecialArgs = { inherit inputs system; };
}
