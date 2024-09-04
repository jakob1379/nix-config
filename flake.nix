
{
  description = "Home Manager configuration of jga";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix.url = "github:nix-community/poetry2nix";
    nixgl.url = "github:nix-community/nixGL";
    zen-browser.url = "github:MarceColl/zen-browser-flake";
    # fabric.url = "path:./flakes/fabric";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixgl, ... }:
    let
      pkgs = import nixpkgs;

      # what systems to build for
      forAllSystems = function:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ]
          (system: function nixpkgs.legacyPackages.${system});

      # Pacakages for nix shell
      generalPackages = pkgs: with pkgs; [
        nodejs
        pre-commit
        yamllint
        gitleaks
      ];

      # Home config generator
      mkHomeConfig = machineModule: system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = [ machineModule ];
        extraSpecialArgs = { inherit inputs system; };
      };
    in {
      # general nix configs
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 2w";
      };
      nix.settings.auto-optimise-store = true;

      # Home configs
      homeConfigurations."pi" = mkHomeConfig ./pi.nix "aarch64-linux";

      # Setup nix shell for this repo
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = (generalPackages pkgs);

          DOCKER_BUILDKIT = 1;

          shellHook = ''
          pre-commit install && pre-commit autoupdate -j $(nproc)
          npm install opencommit
          export PATH=./node_modules/.bin/:$PATH
          export PS1="(dotfiles-shell 🫥) $PS1"
          '';
        };
      });
    };
}
