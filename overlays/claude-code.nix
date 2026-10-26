# Update: curl -fsSL "https://downloads.claude.ai/claude-code-releases/$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)/manifest.zst.json" -o overlays/claude-code-manifest.json
_: prev:

let
  manifest = prev.lib.importJSON ./claude-code-manifest.json;
in
{
  claude-code =
    if prev.lib.versionAtLeast prev.claude-code.version manifest.version then
      prev.claude-code
    else
      prev.claude-code.override { inherit manifest; };
}
