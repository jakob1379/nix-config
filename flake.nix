{
  description = "Home Manager configuration of jga";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waytorandr = {
      url = "github:jakob1379/waytorandr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:youwen5/zen-browser-flake";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      lib = import ./lib { inherit nixpkgs inputs; };
      inherit (lib) forAllSystems generalPackages;
    in
    {
      homeConfigurations = import ./home { inherit lib; };
      nixosConfigurations = import ./nixos { inherit nixpkgs inputs lib; };
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = generalPackages pkgs;
          shellHook = ''
            export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
            if [ ! -f .git/hooks/pre-commit ]; then
              echo "Running pre-commit install for the first time..."
              ${pkgs.prek}/bin/prek install
            fi
            export PS1="(dotfiles-shell 🫥) $PS1"
          '';
        };
      });
    };
}
