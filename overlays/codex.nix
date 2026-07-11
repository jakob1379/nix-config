_final: prev:

{
  codex = prev.codex.overrideAttrs (
    finalAttrs: old:
    let
      cargoHash = "sha256-S4dsZXfmKvJItL2XYKyxfhqdCMATEG6oPjrtVRwkuYc=";
    in
    {
      version = "0.144.1";

      src = prev.fetchFromGitHub {
        owner = "openai";
        repo = "codex";
        tag = "rust-v${finalAttrs.version}";
        hash = "sha256-KHgrqIZyAmLhTZSRYbb7huBO8neOib/B1Vx/oPW2nEU=";
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
