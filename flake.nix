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
    t3code-flake = {
      url = "github:jakob1379/t3code-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:youwen5/zen-browser-flake";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      lib = import ./lib { inherit nixpkgs inputs; };
      inherit (lib) forAllSystems generalPackages;
      overlay = inputs."t3code-flake".overlays.default;
    in
    {
      overlays.default = overlay;

      homeConfigurations = import ./home { inherit lib; };
      nixosConfigurations = import ./nixos { inherit nixpkgs inputs lib; };
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfreePredicate = lib.allowUnfreePredicate;
            overlays = [ overlay ];
          };
        in
        {
          inherit (pkgs) t3code;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux" && builtins.hasAttr "t3code-desktop" pkgs) {
          t3code-desktop = pkgs."t3code-desktop";
        }
      );
      apps = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          packages = self.packages.${system};
        in
        {
          t3code = {
            type = "app";
            program = "${packages.t3code}/bin/t3code";
          };
        }
        // nixpkgs.lib.optionalAttrs (builtins.hasAttr "t3code-desktop" packages) {
          t3code-desktop = {
            type = "app";
            program = "${packages."t3code-desktop"}/bin/t3code";
          };
        }
      );
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
