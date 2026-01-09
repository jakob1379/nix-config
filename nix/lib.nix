{ nixpkgs, inputs }:
let
  mkHomeConfig = import ../lib/mkHomeConfig.nix { inherit inputs; };
  forAllSystems =
    function:
    nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
      system: function nixpkgs.legacyPackages.${system}
    );
  allowUnfreePredicate =
    pkg:
    builtins.elem (pkg.pname or "") [
      "zen-browser"
    ];
  generalPackages =
    pkgs: with pkgs; [
      prek
      yamllint
      nixfmt
      statix
      deadnix
      git-crypt
    ];
in
{
  inherit
    mkHomeConfig
    forAllSystems
    generalPackages
    allowUnfreePredicate
    ;
}
