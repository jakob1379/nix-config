_final: prev:

{
  codex = prev.codex.overrideAttrs (
    finalAttrs: old:
    let
      cargoHash = "sha256-S4dsZXfmKvJItL2XYKyxfhqdCMATEG6oPjrtVRwkuYc=";
    in
    {
      version = "0.144.0";

      src = prev.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v${finalAttrs.version}";
        hash = "sha256-GbLeECsju5jifeVah1xN4HFFHxOKtCj55gl/0ZULj+g=";
      };

      inherit cargoHash;
      cargoDeps = old.cargoDeps.overrideAttrs (cargoDepsOld: {
        vendorStaging = cargoDepsOld.vendorStaging.overrideAttrs (_vendorStagingOld: {
          outputHash = cargoHash;
        });
      });

      cargoBuildFlags = [
        "--package"
        "codex-cli"
        "--package"
        "codex-code-mode-host"
      ];
      cargoCheckFlags = [
        "--package"
        "codex-cli"
        "--package"
        "codex-code-mode-host"
      ];
    }
  );
}
