# Nix Config

Container-first workflows for previewing and publishing the Nix configuration
bundle.

## Docker Quick Start

```bash
git clone https://github.com/jakob1379/nix-config.git
cd nix-config
```

Set the runtime mode for Compose (defaults to `development`):

```bash
export ENVIRONMENT=development   # or production
```

### Live Preview with `docker compose watch`

1. Build and start the stack:

   ```bash
   docker compose up --build
   ```

2. Start the live file sync loop (rebuilds on Dockerfile changes and syncs all
   tracked files into the container so the preview refreshes instantly):

   ```bash
   docker compose watch
   ```

3. Open the local preview at <http://localhost:8000>. Any edits made to the
   repository are synced into `/workspace` inside the container and served
   immediately.

### Publish via Cloudflare Tunnel

Production deployments add a Cloudflare sidecar. Provide your tunnel token and
switch the environment flag:

```bash
export ENVIRONMENT=production
export CLOUDFLARED_TUNNEL_TOKEN="<your-token>"

docker compose up -d
```

The `cloudflared` service waits until `ENVIRONMENT=production` and then runs the
tunnel using the supplied token, exposing the preview externally.

## Compose Layout

- **`app` service** – builds from the local `Dockerfile`, serves the repository
  over Python’s `http.server`, and reacts to file changes through
  `docker compose watch`.
- **`cloudflared` sidecar** – only activates in production mode. In development
  it idles without opening a tunnel.

Environment variables:

| Variable                   | Default       | Purpose                                    |
| -------------------------- | ------------- | ------------------------------------------ |
| `ENVIRONMENT`              | `development` | Toggles dev/production behaviour           |
| `CLOUDFLARED_TUNNEL_TOKEN` | unset         | Required in production to start Cloudflare |

## Nix & Make Targets

Traditional Nix workflows remain available when you prefer not to containerise:

- `make install` installs Nix (via Determinate Systems) and enables flake
  support.
- `nix develop` enters the development shell with the predefined toolchain.

## Contributing

Fork the repository, open a branch, and submit a pull request. For Docker-based
changes, please document any new environment variables or services in the table
above.

## License

MIT – see [LICENSE](LICENSE).
