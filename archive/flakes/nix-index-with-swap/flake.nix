{
  description = "Archived nix-index wrapper that provisions temporary swap";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.writeShellApplication {
          name = "nix-index-swap";
          runtimeInputs = with pkgs; [
            coreutils
            nix-index
            procps
            sudo
            util-linux
          ];
          text = ''
            set -euo pipefail

            SWAP_SIZE="32G"
            PARALLEL_JOBS="2"

            displayUsage() {
              cat <<'EOF'
            usage: nix-index-swap [options]
            options:
              -s <size> | --size <size>       swap file size (default: 32G)
              -j <jobs> | --jobs <jobs>       parallel jobs for nix-index (default: 2)
              -h | --help                     show this dialog

            examples:
              nix-index-swap
              nix-index-swap -s 16G
              nix-index-swap -s 64G -j 8
            EOF
            }

            cleanup() {
              local exit_code=$?

              if [[ -n "''${SWAP_FILE:-}" && -b "$SWAP_FILE" ]]; then
                echo "Deactivating swap on $SWAP_FILE..." >&2
                sudo swapoff "$SWAP_FILE" 2>/dev/null || true
              fi

              if [[ -n "''${SWAP_FILE:-}" && -f "$SWAP_FILE" ]]; then
                echo "Removing temporary swap file $SWAP_FILE..." >&2
                sudo rm -f "$SWAP_FILE" 2>/dev/null || true
              fi

              if (( exit_code != 0 )); then
                echo "Script failed with exit code $exit_code" >&2
                echo "Cleanup completed." >&2
              fi
            }

            trap cleanup EXIT

            for cmd in sudo fallocate free mkswap swapon swapoff nix-index mktemp; do
              if ! command -v "$cmd" >/dev/null 2>&1; then
                echo "Error: Required command '$cmd' not found" >&2
                exit 1
              fi
            done

            while [[ $# -gt 0 ]]; do
              case "$1" in
                -s|--size)
                  [[ $# -ge 2 ]] || {
                    echo "Error: $1 requires an argument" >&2
                    exit 2
                  }
                  SWAP_SIZE="$2"
                  shift 2
                  ;;
                -j|--jobs)
                  [[ $# -ge 2 ]] || {
                    echo "Error: $1 requires an argument" >&2
                    exit 2
                  }
                  PARALLEL_JOBS="$2"
                  shift 2
                  ;;
                -h|--help|help)
                  displayUsage
                  exit 0
                  ;;
                *)
                  echo "Error: Unknown argument '$1'" >&2
                  exit 2
                  ;;
              esac
            done

            if ! [[ "$PARALLEL_JOBS" =~ ^[0-9]+$ ]] || (( PARALLEL_JOBS < 1 )); then
              echo "Error: Parallel jobs must be a positive integer (got: '$PARALLEL_JOBS')" >&2
              exit 1
            fi

            SWAP_FILE="$(mktemp -u /tmp/nix_index_swap.XXXXXXXX)"

            echo "Creating a $SWAP_SIZE temporary swap file at $SWAP_FILE..."
            sudo fallocate -l "$SWAP_SIZE" "$SWAP_FILE"

            echo "Setting permissions for $SWAP_FILE..."
            sudo chmod 600 "$SWAP_FILE"

            echo "Setting up swap on $SWAP_FILE..."
            sudo mkswap "$SWAP_FILE"

            echo "Activating swap on $SWAP_FILE..."
            sudo swapon "$SWAP_FILE"

            echo "Verifying swap is active:"
            free -h

            echo "Running nix-index with $PARALLEL_JOBS parallel job(s)..."
            RAYON_NUM_THREADS="$PARALLEL_JOBS" nix-index

            echo "Nix-index with temporary swap completed successfully."
          '';
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/nix-index-swap";
        };
      }
    );
}
