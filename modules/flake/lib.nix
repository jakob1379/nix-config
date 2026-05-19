{ inputs, ... }:

let
  localLib = import ../../lib {
    nixpkgs = inputs.nixpkgs;
    inherit inputs;
  };
in
{
  flake.lib = localLib // {
    homePackageSets =
      args:
      import ../../modules/home/package-sets.nix (
        args
        // {
          inherit inputs;
        }
      );
  };
}
