{ lib, pkgs }:
let
  # toml-sort 0.24.4 gradle test breaks on tomlkit 0.15 ("Inline tables cannot contain a table"); patch only while nixpkgs still ships it unpatched
  tomlSort =
    if pkgs.toml-sort.version == "0.24.4" && (pkgs.toml-sort.disabledTests or [ ]) == [ ] then
      pkgs.toml-sort.overridePythonAttrs { disabledTests = [ "gradle-version-catalog" ]; }
    else
      lib.warn "toml-sort fixed upstream: remove tomlSort patch in nix/git-hooks.nix" pkgs.toml-sort;
in
{
  src = ../.;
  package = pkgs.prek;
  default_stages = [
    "pre-commit"
    "commit-msg"
    "pre-push"
  ];

  hooks = {
    betterleaks = {
      enable = true;
      name = "betterleaks";
      entry = "${lib.getExe pkgs.betterleaks} git --pre-commit --redact --staged --verbose";
      pass_filenames = false;
    };
    check-added-large-files.enable = true;
    check-case-conflicts.enable = true;
    check-executables-have-shebangs.enable = true;
    check-merge-conflicts.enable = true;
    check-python.enable = true;
    check-shebang-scripts-are-executable.enable = true;
    check-toml.enable = true;
    check-yaml = {
      enable = true;
      after = [ "yamlfix" ];
      args = [ "--unsafe" ];
    };
    codespell = {
      enable = true;
      name = "codespell";
      entry = "${lib.getExe pkgs.codespell} --write-changes";
      types = [ "text" ];
      excludes = [ "(^|/)package-lock\\.json$" ];
    };
    deadnix.enable = true;
    detect-private-keys.enable = true;
    doctoc = {
      enable = true;
      name = "doctoc";
      entry = "${lib.getExe pkgs.doctoc} --notitle";
      files = "^README\\.md$";
    };
    end-of-file-fixer.enable = true;
    fix-byte-order-marker.enable = true;
    keep-sorted = {
      enable = true;
      name = "keep-sorted";
      entry = lib.getExe pkgs.keep-sorted;
      types = [ "text" ];
    };
    mixed-line-endings = {
      enable = true;
      args = [ "--fix=auto" ];
    };
    nixfmt.enable = true;
    prettier = {
      enable = true;
      types_or = [
        "markdown"
        "html"
        "css"
        "scss"
        "javascript"
        "json"
      ];
      settings.prose-wrap = "always";
    };
    python-debug-statements.enable = true;
    ruff.enable = true;
    ruff-format.enable = true;
    shellcheck.enable = true;
    statix = {
      enable = true;
      entry = "${lib.getExe pkgs.statix} fix";
    };
    toml-sort-fix = {
      enable = true;
      name = "toml-sort-fix";
      entry = "${lib.getExe tomlSort} --in-place";
      files = "\\.toml$";
      types = [ "toml" ];
    };
    trim-trailing-whitespace.enable = true;
    check-github-workflows = {
      enable = true;
      after = [ "yamlfix" ];
      name = "check-github-workflows";
      entry = "${lib.getExe pkgs.check-jsonschema} --builtin-schema vendor.github-workflows";
      files = "^\\.github/workflows/.*\\.ya?ml$";
      types = [ "yaml" ];
    };
    yamlfix = {
      enable = true;
      name = "yamlfix";
      entry = lib.getExe pkgs.yamlfix;
      types = [ "yaml" ];
    };
  };
}
