final: prev:

{
  t3code = prev.t3code.overrideAttrs (
    finalAttrs: _oldAttrs: {
      version = "0.0.28";

      src = final.fetchFromGitHub {
        owner = "pingdotgg";
        repo = "t3code";
        tag = "v${finalAttrs.version}";
        hash = "sha256-InVrw9L281QSSPrHSiZuivmb+FkYEd6FkHwHIAAxmGk=";
      };

      pnpmDeps = final.fetchPnpmDeps {
        pnpm = final.pnpm_10;
        inherit (finalAttrs)
          pname
          version
          src
          pnpmWorkspaces
          ;

        fetcherVersion = 4;
        hash = "sha256-+JqW/iI0wdRPxyL7y6ggD/+AvwwZXs9+fSUtG/SgW9s=";
      };
    }
  );
}
