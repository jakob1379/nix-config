# nixpkgs only rpaths node-pty (closed https://github.com/NixOS/nixpkgs/pull/570343 covered all addons); keyring, sharp, ffi-rs etc. still need libstdc++.
final: prev:

let
  onlyNodePty = final.lib.hasInfix "node-pty/prebuilds" (prev.t3code.unwrapped.postFixup or "");
in
{
  t3code =
    if onlyNodePty then
      prev.t3code.override {
        t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: {
          postFixup =
            old.postFixup
            + final.lib.optionalString final.stdenv.hostPlatform.isLinux ''
              find "$out"/libexec/t3code -name '*.node' -path '*linux-${final.stdenv.hostPlatform.node.arch}*' \
                -exec patchelf --add-rpath ${final.lib.makeLibraryPath [ final.stdenv.cc.cc.lib ]} {} +
            '';
        });
      }
    else
      throw "t3code postFixup no longer node-pty-only: check native addons load, then drop overlays/t3code-native-addons.nix";
}
