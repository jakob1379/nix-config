final: prev:

let
  inherit (final.stdenv) hostPlatform;
in
{
  flyline = prev.flyline.overrideAttrs (old: {
    env =
      (old.env or { })
      // final.lib.optionalAttrs (hostPlatform.isLinux && hostPlatform.isx86_64) {
        NIX_CFLAGS_COMPILE = "-mtls-dialect=gnu";
      };

    postCheck = (old.postCheck or "") + ''
      if grep -qa GLIBC_ABI_GNU2_TLS "$library"; then
        echo "libflyline needs GLIBC_ABI_GNU2_TLS; it will not load into a bash on glibc < 2.41" >&2
        exit 1
      fi
    '';

    postFixup =
      (old.postFixup or "")
      + final.lib.optionalString hostPlatform.isLinux ''
        patchelf --remove-rpath "$out/lib/libflyline.so"
      '';
  });
}
