# VM hosts

`base.nix` is the actual config for the only VM host in this tree:
`vm-docker-main`.

If a second VM ever appears, then split shared defaults back out. Until then,
the extra host wrapper is just noise.

## Build a Proxmox image

`nixos-generators` is deprecated. Use the upstream image builder via
`nixos-rebuild` instead.

Note: the current upstream Proxmox image path in `nixpkgs` still emits the
obsolete `proxmox.qemuConf.diskSize` evaluation warning. That warning is
upstream, not caused by files in `nixos/hosts/vm/`.

Example for the existing `vm-docker-main` host:

```bash
nix run nixpkgs#nixos-rebuild -- \
  build-image \
  --flake .#vm-docker-main \
  --image-variant proxmox
```

That builds the Proxmox VMA image from `nixosConfigurations.vm-docker-main`
defined in `base.nix` and leaves a `result` symlink in the current directory.

To see available image variants for a host:

```bash
nix run nixpkgs#nixos-rebuild -- build-image --flake .#vm-docker-main
```

## Create a new machine in Proxmox from the image

1. Build the image for the target host.
2. Copy the resulting `vzdump-qemu-*.vma.zst` file to the Proxmox node.
3. Restore it as a new VM, either in the UI or with `qmrestore`.

CLI example:

```bash
qmrestore /path/to/vzdump-qemu-my-host.vma.zst 123 \
  --storage local-lvm \
  --unique 1
```

- `123` is the new VM ID.
- `--storage` selects where the VM disks should live.
- `--unique 1` is important so Proxmox assigns a fresh MAC address instead of
  reusing the one baked into the archive.

In the Proxmox UI, upload the backup archive, restore it as a new VM, and enable
the `Unique` option during restore.

After restore, review the VM settings in Proxmox before first boot:

1. confirm CPU, memory, disk, and network bridge match the new machine
2. check cloud-init settings if this host should get its network or SSH settings
   from Proxmox
3. start the VM and verify it comes up on the expected hostname and network
