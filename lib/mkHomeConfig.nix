{ inputs, ... }:

let
  opencodeWslOverlay = _final: prev: {
    opencode =
      if prev.stdenv.hostPlatform.system == "x86_64-linux" then
        prev.opencode.overrideAttrs (old: {
          # The opencode >= 1.14.48 Bun standalone executable segfaults under
          # WSL2. Run the same sources through Bun directly until upstream fixes
          # the standalone runtime crash.
          buildPhase = ''
            runHook preBuild

            cd ./packages/opencode
            bun --bun ./script/generate.ts
            bun --bun ./script/schema.ts config.json tui.json

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/share/opencode
            cd ../..
            cp -R --no-preserve=mode . $out/share/opencode/source

            cat > $out/share/opencode/source/nix-entry.ts <<'EOF'
            globalThis.OPENCODE_VERSION = "${old.version}"
            globalThis.OPENCODE_CHANNEL = "stable"
            await import("./packages/opencode/src/index.ts")
            EOF

            cat > $out/bin/opencode <<EOF
            #!${prev.runtimeShell}
            export MODELS_DEV_API_JSON="${prev.models-dev}/dist/_api.json"
            export OPENCODE_DISABLE_MODELS_FETCH="1"
            exec ${prev.bun}/bin/bun --conditions=browser "$out/share/opencode/source/nix-entry.ts" "\$@"
            EOF
            chmod 755 $out/bin/opencode
            wrapProgram $out/bin/opencode \
              --prefix PATH : ${prev.lib.makeBinPath [ prev.ripgrep ]}

            install -Dm644 packages/opencode/config.json $out/share/opencode/config.json
            install -Dm644 packages/opencode/tui.json $out/share/opencode/tui.json

            runHook postInstall
          '';
        })
      else
        prev.opencode;
  };
in
{
  system,
  username,
  homeDirectory,
  extraModules ? [ ],
  lib,
}:

inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfreePredicate = lib.allowUnfreePredicate;
    overlays = [ (import ../overlays/tana.nix) ];
  };
  modules = [
    ../home/common.nix
    {
      home.username = username;
      home.homeDirectory = homeDirectory;
    }
  ]
  ++ extraModules;
  extraSpecialArgs = { inherit inputs system; };
}
