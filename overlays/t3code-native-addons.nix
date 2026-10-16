# Drop once https://github.com/NixOS/nixpkgs/pull/570343 lands in nixos-unstable-small.
final: prev:

{
  t3code = prev.t3code.override {
    t3code-unwrapped = prev.t3code.unwrapped.overrideAttrs (old: {
      postFixup =
        (old.postFixup or "")
        + final.lib.optionalString final.stdenv.hostPlatform.isLinux ''
          find "$out"/libexec/t3code -name '*.node' -path '*linux-${final.stdenv.hostPlatform.node.arch}*' \
            -exec patchelf --add-rpath ${final.lib.makeLibraryPath [ final.stdenv.cc.cc.lib ]} {} +
        '';
    });
  };
}
