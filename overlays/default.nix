{ inputs, nixpkgs }:
let
  enableNoctaliaQsPr35Patch = true;
in
nixpkgs.lib.composeManyExtensions (
  [
    inputs."t3code-flake".overlays.default
  ]
  ++ nixpkgs.lib.optional enableNoctaliaQsPr35Patch (
    _: prev: {
      noctalia-qs = prev.noctalia-qs.overrideAttrs (_: {
        patches = [ ];
        src = prev.fetchFromGitHub {
          owner = "Mic92";
          repo = "noctalia-qs";
          rev = "3f2f20077ede5303cadb82a5b53157f4c80dde3d";
          hash = "sha256-60Y7T+vSDbnWQFDUEcpPuv79xphCZC7vRuStpNRjUuk=";
        };
      });
    }
  )
)
