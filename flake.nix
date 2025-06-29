{
  description = "Home Manager configuration of jga";

  inputs = {
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
      # Import the home configuration generator
      mkHomeConfig = import ./lib/mkHomeConfig.nix { inherit inputs; };

      # Systems to build for
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
          system: function nixpkgs.legacyPackages.${system}
        );

      # Packages for nix shell
      generalPackages =
        pkgs: with pkgs; [
          pre-commit
          yamllint
          nixfmt-rfc-style
        ];
    in
    {
      # NixOS configuration
      nixosConfigurations.ku = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./nixos/ku/configuration.nix ];
      };

      # Home configurations using the new modular structure
      homeConfigurations = {
        "pi@raspberrypi" = mkHomeConfig {
          system = "aarch64-linux";
          username = "pi";
          homeDirectory = "/home/pi";
          extraModules = [ ./modules/systems/pi.nix ];
        };

        "fuzie@Fuzie-pc" = mkHomeConfig {
          system = "x86_64-linux";
          username = "fuzie";
          homeDirectory = "/home/fuzie";
          extraModules = [ ./modules/systems/wsl.nix ];
        };

        "jga@yoga" = mkHomeConfig {
          system = "x86_64-linux";
          username = "jga";
          homeDirectory = "/home/jga";
          extraModules = [ ./modules/systems/yoga.nix ];
        };

        "jga@ku" = mkHomeConfig {
          system = "x86_64-linux";
          username = "jga";
          homeDirectory = "/home/jga";
          extraModules = [ ./modules/systems/ucph.nix ];
        };

        "jga@ubuntu" = mkHomeConfig {
          system = "x86_64-linux";
          username = "jga";
          homeDirectory = "/home/jga";
          extraModules = [ ./modules/systems/ubuntu.nix ];
        };
      };

      # DevShell setup for this repo
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = (generalPackages pkgs);
          buildInputs = with pkgs; [ pre-commit ];
          shellHook = ''
            export PS1="(dotfiles-shell 🫥) 
          '';
        };
      });
    };
}
