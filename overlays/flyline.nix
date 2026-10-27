final: prev:

{
  flyline = prev.flyline.overrideAttrs (old: {
    # shortcut: pinned to ansi-to-tui b9617878, a flyline bump to a new rev falls back to eval-time fetchGit; re-hash then.
    cargoDeps = final.rustPlatform.importCargoLock {
      lockFile = "${old.src}/Cargo.lock";
      outputHashes."ansi-to-tui-8.0.1" = "sha256-kjTxPzF0eIgJqtfsmquAqo1UFt1hXWv4oACFRgnHg9k=";
      allowBuiltinFetchGit = true;
    };
  });
}
