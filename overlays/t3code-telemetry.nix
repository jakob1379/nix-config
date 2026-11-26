# Until nixpkgs#592653 (enableTelemetry ? false) reaches the pinned channel, T3 Code posts PostHog analytics to ingest.t3.codes.
final: prev:

{
  t3code =
    if !(final.lib.functionArgs prev.t3code.override ? enableTelemetry) then
      prev.t3code.overrideAttrs (old: {
        # symlinkJoin interpolates postBuild into buildCommand, so overriding postBuild is a no-op.
        buildCommand = old.buildCommand + ''
          for program in "$out"/bin/*; do
            wrapProgram "$program" --set T3CODE_TELEMETRY_ENABLED false
          done
        '';
      })
    else
      throw "t3code opts out of telemetry upstream: drop overlays/t3code-telemetry.nix";
}
