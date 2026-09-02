# Ahead-of-nixpkgs bump to t3code 0.0.38, mirroring
# https://github.com/NixOS/nixpkgs/pull/558233 (version, src hash, pnpm deps
# hash, electron 41 -> 43).
#
# The old commandInvariants.ts patch for
# https://github.com/pingdotgg/t3code/issues/4647 is gone: 0.0.38 fixes it
# upstream, requireThreadAbsent now treats a soft-deleted thread as absent.
#
# t3code is pulled from nixos-unstable-small (see `fromSmall` in
# lib/mkHomeConfig.nix), so the bumped `t3code-unwrapped` must be built from
# that same package set. It is not a top-level attribute — package.nix only
# takes it as a defaulted argument — so it has to be re-instantiated here
# rather than reached through `.override`'s function form.
#
# .github/workflows/t3code-watch.yml deletes this file once either channel
# ships 0.0.38.
smallPkgs:

_: prev:

{
  t3code = prev.t3code.override {
    t3code-unwrapped =
      (smallPkgs.callPackage "${smallPkgs.path}/pkgs/by-name/t3/t3code/unwrapped.nix" {
        electron_41 = smallPkgs.electron_43;
      }).overrideAttrs
        (prevAttrs: {
          version = "0.0.38";

          src = smallPkgs.fetchFromGitHub {
            owner = "pingdotgg";
            repo = "t3code";
            tag = "v0.0.38";
            hash = "sha256-lbAOIlNwVxrjXA5jJGzmOm7Fe2ZcsnFuDzaSEt6R7G4=";
          };

          # fetchDeps inherits pname/version/src from finalAttrs, so the bump
          # above already reaches it; only the fixed-output hash needs replacing.
          pnpmDeps = prevAttrs.pnpmDeps.overrideAttrs {
            outputHash = "sha256-t/hmpXdYPnBFx18A6NrSL4zSvVnUDIjIPtLjGOzoaDk=";
          };
        });
  };
}
