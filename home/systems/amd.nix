{
  pkgs,
  lib,
  system,
  inputs,
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
  hermesAgent =
    let
      hermesUpstream = inputs.hermes-agent.packages.${system}.default;
      hermesTui = hermesUpstream.hermesTui.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/app/slash/commands/ops.ts \
            --replace-fail \
              'const params: { session_id: string; confirm?: boolean; always?: boolean } = {' \
              'const params: { session_id: string | null; confirm?: boolean; always?: boolean } = {'
        '';
      });
      bundledSkills = lib.cleanSourceWith {
        src = inputs.hermes-agent.outPath + "/skills";
        filter = path: _type: !(lib.hasInfix "/index-cache/" path);
      };
      bundledPlugins = lib.cleanSourceWith {
        src = inputs.hermes-agent.outPath + "/plugins";
        filter = path: _type: !(lib.hasInfix "/__pycache__/" path);
      };
      runtimePath = lib.makeBinPath [
        pkgs.nodejs_22
        pkgs.ripgrep
        pkgs.git
        pkgs.openssh
        pkgs.ffmpeg
        pkgs.tirith
      ];
    in
    pkgs.stdenv.mkDerivation {
      inherit (hermesUpstream) pname;
      inherit (hermesUpstream) version;
      dontUnpack = true;
      dontBuild = true;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      installPhase = ''
        mkdir -p $out/share/hermes-agent $out/bin
        cp -r ${bundledSkills} $out/share/hermes-agent/skills
        cp -r ${bundledPlugins} $out/share/hermes-agent/plugins
        cp -r ${hermesUpstream.hermesWeb} $out/share/hermes-agent/web_dist

        mkdir -p $out/ui-tui
        cp -r ${hermesTui}/lib/hermes-tui/* $out/ui-tui/

        ${lib.concatMapStringsSep "\n"
          (name: ''
            makeWrapper ${hermesUpstream.hermesVenv}/bin/${name} $out/bin/${name} \
              --suffix PATH : "${runtimePath}" \
              --set HERMES_BUNDLED_SKILLS $out/share/hermes-agent/skills \
              --set HERMES_BUNDLED_PLUGINS $out/share/hermes-agent/plugins \
              --set HERMES_WEB_DIST $out/share/hermes-agent/web_dist \
              --set HERMES_TUI_DIR $out/ui-tui \
              --set HERMES_PYTHON ${hermesUpstream.hermesVenv}/bin/python3 \
              --set HERMES_NODE ${pkgs.nodejs_22}/bin/node
          '')
          [
            "hermes"
            "hermes-agent"
            "hermes-acp"
          ]
        }
      '';
      inherit (hermesUpstream) meta;
    };
in
{
  customGit = {
    userName = "Jakob Stender Guldberg";
    userEmail = "jakob1379@gmail.com";
  };

  customPackages = {
    gui.enable = lib.mkForce true;
    core.packages = lib.mkForce (
      builtins.map (
        p:
        if p == pkgs.btop then
          pkgs.btop.override {
            rocmSupport = true;
          }
        else
          p
      ) packageSets.core
    );
  };

  home.packages = lib.mkAfter (
    with pkgs;
    [
      clockify
      adw-gtk3
      glab
      hermesAgent
      # teams-for-linux
      kdePackages.qt6ct
      libsForQt5.qt5ct
      nwg-look
    ]
  );

  programs = {
    codex = {
      enable = true;
    };
  };

  services.tailscale-systray.enable = true;

  customDotfiles = {
    enableMediaControl = true;
  };
}
