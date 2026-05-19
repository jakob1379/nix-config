{
  description = "Home Manager configuration of jga";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
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
      url = "github:NousResearch/hermes-agent/265bd59c1d9f8dea658f243b257d4fae3685af53";
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
    oh-my-opencode-slim-src = {
      url = "github:alvinunreal/oh-my-opencode-slim";
      flake = false;
    };
    agent-browser-src = {
      url = "github:vercel-labs/agent-browser";
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
      flake-parts,
      ...
    }:
    let
      localLib = import ./lib {
        nixpkgs = inputs.nixpkgs;
        inherit inputs;
      };
      inherit (localLib) generalPackages;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        ./modules/flake/lib.nix
        ./modules/flake/home-modules.nix
        ./modules/flake/nixos-modules.nix
        ./modules/flake/home-configurations.nix
        ./modules/flake/nixos-configurations.nix
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          checks.pre-commit-check = inputs.git-hooks.lib.${system}.run (
            import ./nix/git-hooks.nix {
              inherit pkgs;
              inherit (inputs.nixpkgs) lib;
            }
          );

          formatter =
            let
              inherit (self.checks.${system}.pre-commit-check) config;
              inherit (config) configFile package;
            in
            pkgs.writeShellScriptBin "prek-fmt" ''
              ${pkgs.lib.getExe package} run --all-files --config ${configFile}
            '';

          devShells.default =
            let
              inherit (self.checks.${system}) pre-commit-check;
            in
            pkgs.mkShell {
              packages = (generalPackages pkgs) ++ pre-commit-check.enabledPackages;
              shellHook = ''
                ${pre-commit-check.shellHook}
                export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
                export PS1="(dotfiles-shell 🫥) $PS1"
              '';
            };
        };
    };
}
