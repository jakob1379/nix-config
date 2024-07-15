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
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      forAllSystems = function:
        nixpkgs.lib.genAttrs [ "x86_64-linux" ]
          (system: function nixpkgs.legacyPackages.${system});

      generalPackages = pkgs: with pkgs; [
        nodejs
        pre-commit
        yamllint
      ];
    in {
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
          export PS1="(dotfiles-shell 🫥) $PS1"
          '';
        };
      });
    };
}
