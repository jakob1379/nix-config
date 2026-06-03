{
  pkgs,
  lib,
  inputs,
  system,
  ...
}:
let
  packageSets = import ../modules/package-sets.nix {
    inherit
      pkgs
      lib
      system
      inputs
      ;
  };

  coderabbit-cli = inputs.numtide-llm-agents.packages.${system}.coderabbit-cli;
  btopCudaWsl = pkgs.symlinkJoin {
    name = "btop-cuda-wsl";
    paths = [ pkgs.btop-cuda ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/btop \
        --prefix LD_LIBRARY_PATH : /usr/lib/wsl/lib
    '';
  };
  opencodeWslOverlay = _final: prev: {
    opencode = prev.opencode.overrideAttrs (old: {
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

        cat > $out/share/opencode/source/packages/opencode/nix-entry.ts <<'EOF'
        globalThis.OPENCODE_VERSION = "${old.version}"
        globalThis.OPENCODE_CHANNEL = "stable"
        await import("./src/index.ts")
        EOF

        cat > $out/bin/opencode <<EOF
        #!${prev.runtimeShell}
        export MODELS_DEV_API_JSON="${prev.models-dev}/dist/_api.json"
        export OPENCODE_DISABLE_MODELS_FETCH="1"
        args=("\$@")
        case "\''${1-}" in
          ""|-*)
            case " \$* " in
              *" --help "*|*" -h "*|*" --version "*|*" -v "*)
                ;;
              *)
                args+=("\$PWD")
                ;;
            esac
            ;;
          completion|acp|mcp|attach|run|debug|providers|auth|agent|upgrade|uninstall|serve|web|models|stats|export|import|github|pr|session|plugin|plug|db)
            ;;
          *)
            ;;
        esac
        exec ${prev.bun}/bin/bun --cwd "$out/share/opencode/source/packages/opencode" --conditions=browser nix-entry.ts "\''${args[@]}"
        EOF
        chmod 755 $out/bin/opencode
        wrapProgram $out/bin/opencode \
          --prefix PATH : ${prev.lib.makeBinPath [ prev.ripgrep ]}

        install -Dm644 packages/opencode/config.json $out/share/opencode/config.json
        install -Dm644 packages/opencode/tui.json $out/share/opencode/tui.json

        runHook postInstall
      '';
    });
  };
in
{
  nixpkgs.overlays = [ opencodeWslOverlay ];

  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  programs = {
    codex = {
      enable = true;
    };

    emacs.package = lib.mkForce pkgs.emacs-nox;
  };

  services.emacs = {
    enable = lib.mkForce true;
    package = lib.mkForce pkgs.emacs-nox;
    startWithUserSession = lib.mkForce true;
    socketActivation.enable = lib.mkForce false;
    defaultEditor = lib.mkForce false;
    client.enable = lib.mkForce false;
  };

  home = {
    sessionVariables = {
      EDITOR = "emacsclient -t";
      VISUAL = "emacsclient -t";
    };
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      coderabbit-cli
      glab
      btopCudaWsl
    ]
  );

  customPackages = {
    core.packages = lib.mkForce (builtins.filter (p: p != pkgs.btop) packageSets.core);
  };

  customSsh.enableKeepassxc = lib.mkForce false;

}
