{ lib, pkgs }:
{
  src = ../.;
  package = pkgs.prek;
  default_stages = [
    "pre-commit"
    "commit-msg"
    "pre-push"
  ];

  hooks = {
    check-added-large-files.enable = true;
    check-case-conflicts.enable = true;
    check-executables-have-shebangs.enable = true;
    check-merge-conflicts.enable = true;
    check-python.enable = true;
    check-shebang-scripts-are-executable.enable = true;
    check-toml.enable = true;
    check-yaml = {
      enable = true;
      args = [ "--unsafe" ];
    };
    codespell = {
      enable = true;
      name = "codespell";
      entry = "${lib.getExe pkgs.codespell} --write-changes";
      types = [ "text" ];
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
    gitleaks = {
      enable = true;
      name = "gitleaks";
      entry = "${lib.getExe pkgs.gitleaks} protect --verbose --redact --staged";
      pass_filenames = false;
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
      entry = "${lib.getExe pkgs.toml-sort} --in-place";
      files = "\\.toml$";
      types = [ "toml" ];
    };
    trim-trailing-whitespace.enable = true;
    check-github-workflows = {
      enable = true;
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
