final: prev:

let
  inherit (final) lib;
  src = prev.flyline.src;
  needed =
    lib.hasInfix "git+https://github.com/HalFrgrd/ansi-to-tui" (builtins.readFile "${src}/Cargo.lock")
    && !lib.hasInfix "outputHashes" (builtins.readFile "${src}/nix/package.nix");
in
{
  flyline =
    if needed then
      prev.flyline.overrideAttrs (old: {
        # shortcut: pinned to ansi-to-tui b9617878, a flyline bump to a new rev falls back to eval-time fetchGit; re-hash then.
        cargoDeps = final.rustPlatform.importCargoLock {
          lockFile = "${old.src}/Cargo.lock";
          outputHashes."ansi-to-tui-8.0.1" = "sha256-kjTxPzF0eIgJqtfsmquAqo1UFt1hXWv4oACFRgnHg9k=";
          allowBuiltinFetchGit = true;
        };
      })
    else
      throw "flyline no longer needs the ansi-to-tui outputHash: drop overlays/flyline.nix";
}
