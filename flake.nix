{
  description = "Home Manager configuration of jga";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
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
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    navi-cheats-src = {
      url = "github:denisidoro/cheats";
      flake = false;
    };
    navi-tldr-pages-src = {
      url = "github:denisidoro/navi-tldr-pages";
      flake = false;
    };
    tmux-ping-src = {
      url = "github:ayzenquwe/tmux-ping";
      flake = false;
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      git-hooks,
      nixpkgs,
      ...
    }:
    let
      lib = import ./lib { inherit nixpkgs inputs; };
      inherit (lib) forAllSystems generalPackages;
      enableNoctaliaQsPr35Patch = true;
      overlay = nixpkgs.lib.composeManyExtensions (
        [
          inputs."t3code-flake".overlays.default
        ]
        ++ nixpkgs.lib.optional enableNoctaliaQsPr35Patch (
          _: prev: {
            noctalia-qs = prev.noctalia-qs.overrideAttrs (_: {
              patches = [ ];
              src = prev.fetchFromGitHub {
                owner = "Mic92";
                repo = "noctalia-qs";
                rev = "3f2f20077ede5303cadb82a5b53157f4c80dde3d";
                hash = "sha256-60Y7T+vSDbnWQFDUEcpPuv79xphCZC7vRuStpNRjUuk=";
              };
            });
          }
        )
      );
    in
    {
      overlays.default = overlay;

      homeConfigurations = import ./home { inherit lib; };
      nixosConfigurations = import ./nixos { inherit nixpkgs inputs lib; };
      checks = forAllSystems (pkgs: {
        pre-commit-check = git-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run (
          import ./nix/git-hooks.nix {
            inherit pkgs;
            inherit (nixpkgs) lib;
          }
        );
      });
      formatter = forAllSystems (
        pkgs:
        let
          inherit (self.checks.${pkgs.stdenv.hostPlatform.system}.pre-commit-check) config;
          inherit (config) configFile package;
        in
        pkgs.writeShellScriptBin "prek-fmt" ''
          ${pkgs.lib.getExe package} run --all-files --config ${configFile}
        ''
      );
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
        default =
          let
            inherit (self.checks.${pkgs.stdenv.hostPlatform.system}) pre-commit-check;
          in
          pkgs.mkShell {
            packages = (generalPackages pkgs) ++ pre-commit-check.enabledPackages;
            shellHook = ''
              ${pre-commit-check.shellHook}

              export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
              export PS1="(dotfiles-shell 🫥) $PS1"
            '';
          };
      });
    };
}
