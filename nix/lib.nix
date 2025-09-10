{ nixpkgs, inputs }:
let
  mkHomeConfig = import ../lib/mkHomeConfig.nix { inherit inputs; };
  forAllSystems =
    function:
    nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
      system: function nixpkgs.legacyPackages.${system}
    );
  generalPackages = pkgs: with pkgs; [
    pre-commit
    yamllint
    nixfmt-rfc-style
    statix
    deadnix
  ];
in {
  inherit mkHomeConfig forAllSystems generalPackages;
}
