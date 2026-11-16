<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Nix config](#nix-config)
  - [Quick start](#quick-start)
  - [Layout](#layout)
  - [Main outputs](#main-outputs)
  - [TPM disk unlock](#tpm-disk-unlock)

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
```

## Layout

- `flake.nix` — flake entrypoint, outputs, checks, dev shell
- `home/` — Home Manager profiles, shared modules, per-system overrides
- `nixos/` — NixOS hosts, shared defaults, user modules
- `dotfiles/` — editor, shell, browser, terminal, and desktop configs
- `bin/` — custom helper commands wrapped into packages
- `tests/` — end-to-end check for `bin/nix-find`, run by `nix flake check`
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

## TPM disk unlock

Every LUKS device has `tpm2-device=auto` in its initrd crypttab
(`nixos/tpm-luks.nix`), so the TPM unlocks the disk and the passphrase stays as
the fallback. It does nothing until the TPM is enrolled once per machine:

```bash
dev=$(sudo cryptsetup status /dev/mapper/luks-* | awk '/device:/ {print $2}')
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 "$dev"
sudo cryptsetup luksDump "$dev" | grep -A2 Tokens   # shows systemd-tpm2
```

Reboot; it must reach the login screen without a prompt.

- No Secure Boot means PCR 7 protects a removed disk, not a stolen laptop: any
  OS booted on that machine gets the key.
- After a firmware update or a Secure Boot change the TPM refuses. Type the
  passphrase, then rerun the enrol command with `--wipe-slot=tpm2`.
- Enrolment needs a LUKS2 header (`cryptsetup luksDump` shows `Version: 2`).
