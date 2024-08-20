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
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nixgl.overlay ];  # Apply the nixGL overlay
      };

      forAllSystems = function:
        nixpkgs.lib.genAttrs [ "x86_64-linux" ]
          (system: function nixpkgs.legacyPackages.${system});

      generalPackages = pkgs: with pkgs; [
        nodejs
        pre-commit
        yamllint
      ];
    in {
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 2w";
      };
      nix.settings.auto-optimise-store = true;

      homeConfigurations."jga" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./home-manager.nix
          ./dotfiles.nix
          ./packages.nix
          ./programs.nix
          ./services.nix
          ./ubuntu.nix
          ./Anemo.nix
        ];

        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
      };

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
