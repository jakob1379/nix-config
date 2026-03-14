{ inputs, ... }:

{
  system,
  username,
  homeDirectory,
  extraModules ? [ ],
  lib,
}:

let
  shikaneOverlay =
    _: prev:
    let
      shikanectlWrapper = prev.writeText "shikanectl-wrapper" (
        builtins.replaceStrings
          [
            "@runtimePath@"
            "@realShikanectl@"
          ]
          [
            "${
              prev.lib.makeBinPath [
                prev.coreutils
                prev.difftastic
                prev.yq-go
              ]
            }:$PATH"
            "${prev.shikane}/bin/shikanectl"
          ]
          (builtins.readFile ../bin/shikanectl)
      );
    in
    {
      shikane = prev.symlinkJoin {
        inherit (prev.shikane) name;
        paths = [ prev.shikane ];
        inherit (prev.shikane) meta;
        passthru = prev.shikane.passthru or { };
        postBuild = ''
          rm "$out/bin/shikanectl"
          cp ${shikanectlWrapper} "$out/bin/shikanectl"
          chmod +x "$out/bin/shikanectl"
        '';
      };
    };
in
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = lib.allowUnfreePredicate;
    overlays = [ shikaneOverlay ];
  };
  modules = [
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
