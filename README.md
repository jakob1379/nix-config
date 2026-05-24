<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Nix config](#nix-config)
  - [Quick start](#quick-start)
  - [Layout](#layout)
  - [Main outputs](#main-outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Nix config

Personal Nix flake for NixOS systems, Home Manager profiles, dotfiles, and
custom helper scripts.

## Quick start

```bash
git clone https://github.com/jakob1379/nix-config.git
cd nix-config
./install.sh
nix develop
```

Useful commands:

```bash
nix fmt
nix flake show
hs
hsu
update-all
```

`hs` switches the current user's Home Manager profile for the current host.
`hsu` updates the flake first, then switches the same profile. `update-all`
updates channels and the flake, switches Home Manager, runs user tool updates,
and switches the current NixOS host.

The switch helpers use `nix-fast-build` to prebuild exact flake outputs before
activation. They intentionally avoid broad targets like `.#`, because recursive
flake traversal can enter non-buildable input functions. Override the inferred
targets with `HM_TARGET=user@host` or `NIXOS_TARGET=host`, tune parallelism with
`NIX_FAST_BUILD_JOBS`, or set `NIX_FAST_BUILD_DISABLE=1` to use the direct
`home-manager` / `nixos-rebuild` paths.

## Layout

- `flake.nix` — flake entrypoint, outputs, checks, dev shell
- `home/` — Home Manager profiles, shared modules, per-system overrides
- `nixos/` — NixOS hosts, shared defaults, user modules
- `dotfiles/` — editor, shell, browser, terminal, and desktop configs
- `bin/` — custom helper commands wrapped into packages
- `scripts/` — supporting scripts for desktop, wallpaper, SSH, and shell
  workflows
- `lib/` — shared helpers used by flake outputs
- `overlays/` — package overlays
- `nix/` — repo checks and git hook configuration
- `archive/` — legacy/archived experiments

## Main outputs

- `homeConfigurations` — Home Manager profiles
- `nixosConfigurations` — NixOS host configs
- `packages` / `apps` — exported packages and runnable apps
- `devShells.default` — development environment with hooks
- `formatter` / `checks` — formatting and validation
