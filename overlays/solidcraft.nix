inputs: final: _:

let
  inherit (final) lib;
  upstream = inputs.solidcraft.packages.${final.stdenv.hostPlatform.system}.default;
  lockFile = "${inputs.solidcraft}/Cargo.lock";
  flake = builtins.readFile "${inputs.solidcraft}/flake.nix";
  revHashes = {
    "8ddce901671f1cebd9214a31d21895d725e886c8" = "sha256-SziXzxkQXY29PBOG7Ct3W8dex4RUWfAEczFUakB0k50=";
    "f5e8e9a29e0c9b7cf6c4040a5bc8878382b3c62f" = "sha256-5LUUk4lmC3igIXyHnmJEXj17je0gEH9AoB0iTd5z0A0=";
  };
  gitDeps = lib.filter (p: lib.hasPrefix "git+" (p.source or "")) (lib.importTOML lockFile).package;
  broken =
    gitDeps != [ ] && !lib.hasInfix "outputHashes" flake && !lib.hasInfix "allowBuiltinFetchGit" flake;
  hashFor =
    p:
    let
      rev = lib.last (lib.splitString "#" p.source);
    in
    revHashes.${rev}
      or (throw "solidcraft: no hash for ${p.name}-${p.version} at ${p.source}; add `nurl -f fetchgit <repo> ${rev}` to revHashes in overlays/solidcraft.nix");
in
{
  solidcraft =
    if !broken then
      lib.warn "solidcraft vendors its git deps upstream: drop overlays/solidcraft.nix" upstream
    else
      upstream.overrideAttrs {
        cargoDeps = final.rustPlatform.importCargoLock {
          inherit lockFile;
          outputHashes = lib.listToAttrs (
            map (p: lib.nameValuePair "${p.name}-${p.version}" (hashFor p)) gitDeps
          );
        };
      };
}
