{ lib, ... }:
{
  # Extends the submodule so every LUKS device on every host tries the TPM
  # first; without an enrolled tpm2 token it falls back to the passphrase.
  options.boot.initrd.luks.devices = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      }
    );
  };
}
