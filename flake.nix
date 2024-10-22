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

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    nixgl,
    ...
  }:
  let
    pkgs = import nixpkgs;

    # Systems to build for
    forAllSystems =
      function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});

    # Packages for nix shell
    generalPackages =
      pkgs: with pkgs; [
        nodejs
        pre-commit
        yamllint
        gitleaks
        nixfmt-rfc-style
      ];

    # Home config generator
    mkHomeConfig =
      modules: system:
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { inherit system; };
        modules = modules; # Accepts a list of modules
        extraSpecialArgs = {
          inherit inputs system;
        };
      };
  in
    {
      # NixOS configuration
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
        ];
      };

      # General nix configurations
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 2w";
      };
      nix.settings.auto-optimise-store = true;

      # Home configurations
      homeConfigurations."pi@raspberrypi" = mkHomeConfig [
        ./pi.nix
        ./services.nix
        ./programs.nix
      ] "aarch64-linux";
      homeConfigurations."fuzie@Fuzie-pc" = mkHomeConfig [
        ./wsl.nix
        ./services.nix
        ./programs.nix
      ] "x86_64-linux";
      homeConfigurations."jga@nixos" = mkHomeConfig [
        ./laptop.nix
        ./services.nix
        ./programs.nix
      ] "x86_64-linux";

      # DevShell setup for this repo
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # Specify the packages that are required
          packages = (generalPackages pkgs);

          # Use the `buildInputs` to include npm and other tools directly
          buildInputs = [ pkgs.pre-commit ];

          # Define a `shellHook` that only sets the environment, not installs things
          shellHook = ''
            export PATH=./node_modules/.bin/:$PATH
            export PS1="(dotfiles-shell 🫥) $PS1"
          '';

          # Use `postBuild` hook to run actions that need to happen after build
          postBuild = ''
            pre-commit install
            pre-commit autoupdate -j $(nproc)
          '';
        };
      });
    };
}
