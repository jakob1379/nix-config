{
  description = "busylight-for-humans packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        poetry2nixOverrides = poetry2nix.overrides.withDefaults (self: super: {
          bitvector = super.bitvector.overrideAttrs (oldAttrs: {
            src = pkgs.fetchFromGitHub {
              owner = "JnyJny";
              repo = "bitvector";
              rev = "e0bc30c3eeccaa992f5f412ec213c645c753c8eb";
              sha256 = "sha256-GVTRD83tq/Hea53US4drOD5ruoYCLTVd24aZOSdDsSo=";
            };
          });
        });

        busylightApp = poetry2nix.mkPoetryApplication {
          projectDir = pkgs.fetchFromGitHub {
            owner = "JnyJny";
            repo = "busylight";
            rev = "0.28.0";
            sha256 = "sha256-OGcq+mrjaKUIAyLR8tknX+I5EDmVCBVZE406K4+PaWc=";
          };
          overrides = poetry2nixOverrides;
        };
      in {
        packages = {
          busylight = busylightApp;
          default = busylightApp;
        };

        devShells.default = pkgs.mkShell { inputsFrom = [ busylightApp ]; };
      });
}
