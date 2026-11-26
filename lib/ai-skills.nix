{ inputs, lib }:
let
  # prototype is left out: mattpocock-skills ships a skill with the same name.
  emilSkills = lib.mapAttrs (name: _: "${inputs.emil-skill-src}/skills/${name}") (
    lib.filterAttrs (name: type: type == "directory" && name != "prototype") (
      builtins.readDir "${inputs.emil-skill-src}/skills"
    )
  );
in
emilSkills
// {
  aggregate-code-quality-report = ../dotfiles/skills/aggregate-code-quality-report;
  converge-review = "${inputs.converge-review-src}/skills/converge-review";
  frontend-design = "${inputs.claude-plugins-src}/plugins/frontend-design/skills/frontend-design";
  progress-party = ../dotfiles/skills/progress-party;
  redesign = ../dotfiles/skills/redesign;
  unslop = "${inputs.cursor-plugins-src}/pstack/skills/unslop";
}
