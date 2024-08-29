{
  description = "A flake to install the up script with gum";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "up-script";
          version = "1.0.0";

          src = self;

          buildInputs = [ pkgs.gum ];

          installPhase = ''
            mkdir -p $out/bin
            cp $src/scripts/up $out/bin/up
          '';
        };

        devShell = pkgs.mkShell {
          buildInputs = [ self.packages.${system}.default ];
          shellHook = ''
            export PATH=$PATH:${pkgs.gum}/bin
          '';
        };

        defaultPackage = self.packages.${system}.default;
        defaultApp = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
          name = "up";
        };
      });
}
