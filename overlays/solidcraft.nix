inputs: final: _:

let
  upstream = inputs.solidcraft.packages.${final.stdenv.hostPlatform.system}.default;
  cargoLock = builtins.readFile "${inputs.solidcraft}/Cargo.lock";
  flake = builtins.readFile "${inputs.solidcraft}/flake.nix";
  solidcoreRev = "8ddce901671f1cebd9214a31d21895d725e886c8";
  broken =
    final.lib.hasInfix "git+https://github.com/tangency-labs/solidcore" cargoLock
    && !final.lib.hasInfix "outputHashes" flake
    && !final.lib.hasInfix "allowBuiltinFetchGit" flake;
in
{
  solidcraft =
    if !broken then
      final.lib.warn "solidcraft vendors solidcore upstream: drop overlays/solidcraft.nix" upstream
    else if final.lib.hasInfix solidcoreRev cargoLock then
      upstream.overrideAttrs {
        cargoDeps = final.rustPlatform.importCargoLock {
          lockFile = "${inputs.solidcraft}/Cargo.lock";
          outputHashes."solidcore-1.0.1" = "sha256-SziXzxkQXY29PBOG7Ct3W8dex4RUWfAEczFUakB0k50=";
        };
      }
    else
      throw "solidcraft: solidcore rev in Cargo.lock moved off ${solidcoreRev}; re-hash with `nurl https://github.com/tangency-labs/solidcore <rev>` in overlays/solidcraft.nix";
}
