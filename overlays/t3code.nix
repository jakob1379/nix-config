# t3code is pulled from nixos-unstable-small (see `fromSmall` in
# lib/mkHomeConfig.nix), so the patched `t3code-unwrapped` must be built from
# that same package set rather than the main nixpkgs one.
smallPkgs:

_: prev:

{
  # Upstream https://github.com/pingdotgg/t3code/issues/4647: when thread
  # bootstrap fails (e.g. the worktree's `git fetch` errors), the rollback
  # soft-deletes the thread, but requireThreadAbsent matches on id alone and
  # ignores deletedAt. The id is burned permanently, and the web client — whose
  # projections all filter `deleted_at IS NULL` — believes it is still free and
  # keeps retrying it, wedging the draft with "already exists and cannot be
  # created twice".
  #
  # Treat a soft-deleted thread as absent. Safe because thread.created resets
  # deletedAt to null and fully replaces the row in both the decider read model
  # and the SQL projection, so a revived id yields a fully visible thread.
  #
  # t3code-unwrapped is not a top-level attribute — package.nix only takes it as
  # a defaulted argument — so it has to be re-instantiated here rather than
  # reached through `.override`'s function form.
  t3code = prev.t3code.override {
    t3code-unwrapped =
      (smallPkgs.callPackage "${smallPkgs.path}/pkgs/by-name/t3/t3code/unwrapped.nix" { }).overrideAttrs
        (prevAttrs: {
          postPatch = (prevAttrs.postPatch or "") + ''
            substituteInPlace apps/server/src/orchestration/commandInvariants.ts \
              --replace-fail 'if (!findThreadById(input.readModel, input.threadId)) {' \
                             'if (findThreadById(input.readModel, input.threadId)?.deletedAt !== null) {'
          '';
        });
  };
}
