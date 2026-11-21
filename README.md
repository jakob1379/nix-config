<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Nix config](#nix-config)
  - [Quick start](#quick-start)
  - [Layout](#layout)
  - [Main outputs](#main-outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Nix config

<p align="center">
  <img src=".github/assets/flake-graph.svg" width="920" alt="Flake inputs such as nixpkgs and home-manager flow through flake.nix into six NixOS hosts and seven Home Manager profiles">
</p>

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
```

## Layout

- `flake.nix` — flake entrypoint, outputs, checks, dev shell
- `home/` — Home Manager profiles, shared modules, per-system overrides
- `nixos/` — NixOS hosts, shared defaults, user modules
- `dotfiles/` — editor, shell, browser, terminal, and desktop configs
- `bin/` — custom helper commands wrapped into packages
- `tests/` — end-to-end check for `bin/nix-find` and a NixOS VM test that runs
  `install.sh` and activates `jsg@amd`, both run by `nix flake check`
  (`nix build .#checks.x86_64-linux.vm-install` for the VM test alone)
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
- `packages.x86_64-linux.portable-shell` — static tmux, flyline and CLI tools
  (bat, eza, fd, fzf, ripgrep, starship, zoxide) with this config, for hosts
  without Nix:

  ```bash
  nix build .#portable-shell
  ssh host 'mkdir -p ~/.local/portable ~/.config/tmux'
  rsync -rLc --chmod=u+w --delete result/ host:.local/portable/
  # once: ssh host 'ln -s ~/.local/portable/tmux.conf ~/.config/tmux/tmux.conf'
  # and add to the remote ~/.bashrc: . ~/.local/portable/bashrc
  ```

- `devShells.default` — development environment with hooks
- `formatter` / `checks` — formatting and validation
