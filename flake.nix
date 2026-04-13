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
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      lib = import ./lib { inherit nixpkgs inputs; };
      inherit (lib) forAllSystems generalPackages;
      overlay =
        final: prev:
        let
          t3codeVersion = "0.0.17";
        in
        {
          t3code =
            let
              base = final.writeShellApplication {
                name = "t3";
                runtimeInputs = [ final.nodejs_24 ];
                text = ''
                  exec npx --yes t3 "$@"
                '';
              };
            in
            final.symlinkJoin {
              name = "t3code";
              paths = [ base ];
              postBuild = ''
                ln -s "$out/bin/t3" "$out/bin/t3code"
              '';
              meta = with final.lib; {
                description = "Wrapper for the T3 Code CLI";
                homepage = "https://github.com/pingdotgg/t3code";
                license = licenses.mit;
                mainProgram = "t3";
                platforms = platforms.linux;
              };
            };

          t3code-desktop =
            if prev.stdenv.hostPlatform.system != "x86_64-linux" then
              throw "t3code-desktop is only supported on x86_64-linux"
            else
              final.appimageTools.wrapType2 rec {
                pname = "t3code-desktop";
                version = t3codeVersion;

                src = final.fetchurl {
                  url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
                  hash = "sha256-uS+o1nRA3R7hn9BaomrdsGVC8UcpPFFRG3a1qGVrs8w=";
                };

                meta = with final.lib; {
                  description = "T3 Code desktop application";
                  homepage = "https://github.com/pingdotgg/t3code";
                  license = licenses.mit;
                  mainProgram = "t3code";
                  platforms = [ "x86_64-linux" ];
                };
              };
        };
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = lib.allowUnfreePredicate;
          overlays = [ overlay ];
        };
    in
    {
      overlays.default = overlay;

      homeConfigurations = import ./home { inherit lib; };
      nixosConfigurations = import ./nixos { inherit nixpkgs inputs lib; };
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          inherit (pkgs) t3code;
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          inherit (pkgs) t3code-desktop;
        }
      );
      apps = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          packages = self.packages.${system};
        in
        {
          t3 = {
            type = "app";
            program = "${packages.t3code}/bin/t3";
          };
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          t3code-desktop = {
            type = "app";
            program = "${packages.t3code-desktop}/bin/t3code";
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
