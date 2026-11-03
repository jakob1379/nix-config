final: prev:

let
  previewBrowser = "${prev.t3code.unwrapped.src}/apps/server/src/preview/PreviewBrowser.ts";
  downloadsChrome =
    builtins.pathExists previewBrowser
    && final.lib.hasInfix "chrome-for-testing-public" (builtins.readFile previewBrowser);
in
{
  t3code =
    if downloadsChrome then
      prev.t3code.override {
        t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            substituteInPlace apps/server/src/preview/PreviewBrowser.ts \
              --replace-fail 'const executable = path.join(installRoot, release.version, executableName);' \
                             'const executable = "${final.lib.getExe final.chromium}";'
          '';
        });
      }
    else
      final.lib.warn "t3code no longer downloads chrome-headless-shell: drop overlays/t3code-preview-browser.nix" prev.t3code;
}
