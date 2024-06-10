{
  description = "A Nix flake for EDA with Python including the dtale package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

        dtale = pkgs.python3Packages.buildPythonPackage rec {
          pname = "dtale";
          version = "3.12.0";
          src = pkgs.python3Packages.fetchPypi {
            inherit pname version;
            sha256 = "4f011fcceabd5708a8aba9665d1e26cf68569c6867a96bed6fb34a9225b26e60";
          };
          propagatedBuildInputs = with pkgs.python3Packages; [ flask pandas ];
          doCheck = false;
        };

        myPythonEnv = pkgs.python3.withPackages (ps: with ps; [
          dtale
          rich
          ipython
          pandas
          seaborn
          plotly
        ]);

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ myPythonEnv ];
        };
      }
    );
}
