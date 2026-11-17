# n8n-Docker

The official [n8n](https://github.com/n8n-io/n8n) image with a node security overlay. When a newer node patch of the same major is out than the one n8n ships, the build replaces n8n's node binary with it. Once upstream catches up, the overlay does nothing. This repo contains only the Dockerfile, the scripts and a build workflow. The upstream code is not forked.

| Image | Tags |
|---|---|
| `ghcr.io/jaytalge/n8n` | `<version>` (e.g. `2.48.4`), `<minor>` (e.g. `2.48`), `latest` |

## Build

- Every day at 02:17 UTC the workflow takes the newest patch of the **last 3 minor lines** up to n8n's stable `latest` (betas/`next` are skipped). A host pinned to `:2.47` keeps getting `2.47.x` fixes.
- A version is rebuilt when it is new or when a newer node patch is out (label `de.jason-talge.build-key` = `<version>/node-<node>`).
- Before pushing, the image is smoke-tested (`/healthz`, `n8n --version`, node not older than the overlay).
- To build manually, use Actions → "Build image from upstream release" → Run workflow. You can enter a specific version and choose "force". A manual version build also moves its `<minor>` tag.
- `/etc/node-overlay` in the image records what the overlay did.

## Usage

```yaml
services:
  n8n:
    image: ghcr.io/jaytalge/n8n:2.48   # patch updates via Watchtower, minor bumps by hand
```

For automatic patch updates, pin the minor tag and let Watchtower update the container. Switch to a new minor line by hand.
