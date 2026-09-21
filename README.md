# WP-CLI + WP Engine

Manage WP Engine WordPress environments from the command line with [WP-CLI](https://make.wordpress.org/cli/), run entirely in a Docker container — nothing needs to be installed on the host besides Docker.

[![Docker Image](https://img.shields.io/docker/v/teejeer/wpcli-wpe?label=Docker%20Hub&logo=docker)](https://hub.docker.com/r/teejeer/wpcli-wpe)
[![Docker Pulls](https://img.shields.io/docker/pulls/teejeer/wpcli-wpe?logo=docker)](https://hub.docker.com/r/teejeer/wpcli-wpe)

> Prebuilt image: **[docker.io/teejeer/wpcli-wpe](https://hub.docker.com/r/teejeer/wpcli-wpe)** — `docker pull teejeer/wpcli-wpe`

## Requirements

- Docker
- An SSH key (ed25519) whose **public** half is added to your **WP Engine User Portal → SSH Keys (SSH Gateway)**
- SSH Gateway enabled on the target environment (per-environment setting in the portal)

## Quick start

```bash
# 1. Get the container image (Alpine + PHP + WP-CLI + ssh + mysql client)
docker pull teejeer/wpcli-wpe           # prebuilt image on Docker Hub
# ...or build it yourself:
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

## Docker image

| | |
|---|---|
| Image | [`teejeer/wpcli-wpe`](https://hub.docker.com/r/teejeer/wpcli-wpe) |
| Base | Alpine 3.20 · PHP 8.3 (+ common extensions) · WP-CLI · openssh-client · mysql client · composer |
| Tags | `latest` |
| Build yourself | `docker build -t wpcli-wpe .` |

The `wp` wrapper looks for an image named `wpcli-wpe` by default. If you pulled
it from Docker Hub instead of building it, either retag it once:

```bash
docker tag teejeer/wpcli-wpe wpcli-wpe
```

or point the wrapper at the full image name:

```bash
export WPE_IMAGE=teejeer/wpcli-wpe
```

The image contains **no secrets** — your SSH key is mounted read-only at
runtime and never baked in.

## Use it with OpenCode (or any AI agent)

This repo doubles as an agent-friendly toolbox: the `wp` wrapper is a plain
non-interactive CLI, so an [OpenCode](https://opencode.ai) agent (or Claude
Code, Copilot, etc.) can run WP-CLI commands on your WP Engine environments
while you work.

Just clone the repo and open it in OpenCode, then ask things like:

```
> check which plugins are out of date on staging
> list admin users on production
> what's the largest database table on staging?
```

Tips to make it work well:

- `AGENTS.md` (in this repo) tells the agent the syntax (`./wp <env> <command>`)
  and the gotchas before it tries anything.
- Keep environment names in `NOTES.md` § 5 — the agent reads them to know
  which environments exist.
- The agent runs inside your shell, so it uses the same SSH key and Docker
  image; no extra credentials are exposed to it.

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
| `Dockerfile` | Builds the `wpcli-wpe` image (published as `teejeer/wpcli-wpe` on Docker Hub) |
| `wp` | Wrapper script (entry point for everything) |
| `wp-cli.yml` | Optional alias mappings — example file, no secrets |
| `AGENTS.md` | Instructions for AI agents (OpenCode etc.) working in this repo |
| `NOTES.md` | Team runbook: setup details, gotchas, troubleshooting |
