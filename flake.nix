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
    nixgl.url = "github:nix-community/nixGL";
    zen-browser.url = "github:youwen5/zen-browser-flake";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
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
          pre-commit
          yamllint
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
      nixosConfigurations.ku = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./nixos/configuration.nix
        ];
      };

      # General nix configurations
      nix.settings.auto-optimise-store = true;
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 1w";
      };

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
      homeConfigurations."jga@yoga" = mkHomeConfig [
        ./yoga.nix
        ./services.nix
        ./programs.nix
      ] "x86_64-linux";
      homeConfigurations."jga@ku" = mkHomeConfig [
        ./ucph.nix
        ./services.nix
        ./programs.nix
      ] "x86_64-linux";

      # DevShell setup for this repo
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # Specify the packages that are required
          packages = (generalPackages pkgs);

          # Use the `buildInputs` to include npm and other tools directly
          buildInputs = with pkgs; [ pre-commit ];

          # Define a `shellHook` that only sets the environment, not installs things
          shellHook = ''
            export PS1="(dotfiles-shell 🫥) $PS1"
          '';

          setupHook = ''
            pre-commit install
            pre-commit autoupdate -j $(nproc)
          '';
        };
      });
    };
}
