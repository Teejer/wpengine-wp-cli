# WP-CLI + WP Engine

Manage WP Engine WordPress environments from the command line with [WP-CLI](https://make.wordpress.org/cli/), run entirely in a Docker container — nothing needs to be installed on the host besides Docker.

## Requirements

- Docker
- An SSH key (ed25519) whose **public** half is added to your **WP Engine User Portal → SSH Keys (SSH Gateway)**
- SSH Gateway enabled on the target environment (per-environment setting in the portal)

## Quick start

```bash
# 1. Build the container image (Alpine + PHP + WP-CLI + ssh + mysql client)
docker build -t wpcli-wpe .

# 2. Run any WP-CLI command against an environment
./wp mysite plugin list
./wp mysite option get siteurl
./wp mysite core version

# 3. Or get an interactive shell on the WP Engine server
./wp mysite shell
```

`<env>` is the environment name from the User Portal (the same name used in
`<env>.wpengine.com`). The wrapper connects as
`<env>@<env>.ssh.wpengine.net` and runs WP Engine's on-server `wp` from
`/sites/<env>`, the WordPress root.

## Configuration

| Setting | Default | How to change |
|---|---|---|
| SSH private key | `~/.ssh/id_ed25519` | `export WPE_SSH_KEY=~/.ssh/my_other_key` |
| Container image | `wpcli-wpe` | `export WPE_IMAGE=myregistry/wpcli-wpe` |
| Short aliases | none | See `wp-cli.yml` examples (copy, uncomment) |

**No secrets belong in this repo.** The private key stays in `~/.ssh/` and is
mounted into the container read-only at runtime; it is copied inside the
throwaway container with safe permissions and destroyed when the container exits.

## Why not `wp --ssh=...`?

WP-CLI's built-in SSH transport malforms the ssh invocation against WP
Engine's gateway (it drops the `user@host`), so it always fails with
`Cannot connect over SSH using provided configuration`. This wrapper instead
ssh's directly and runs the remote `wp` binary that WP Engine ships. See
`NOTES.md` for more gotchas (remote WP root path, older remote wp feature
set, ssh key permission quirks).

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds the `wpcli-wpe` image |
| `wp` | Wrapper script (entry point for everything) |
| `wp-cli.yml` | Optional alias mappings — example file, no secrets |
| `NOTES.md` | Team runbook: setup details, gotchas, troubleshooting |
