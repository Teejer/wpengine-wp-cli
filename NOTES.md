# WP Engine environments runbook

**Purpose:** manage WP Engine WordPress environments from the command line using WP-CLI in a Docker container.

---

## 1. What's installed

| File | What it is |
|---|---|
| `Dockerfile` | Builds the `wpcli-wpe` Docker image: Alpine 3.20, PHP 8.3 (+ common extensions), WP-CLI, openssh-client, mysql client, composer. |
| `wp` | Wrapper script. Starts the container, mounts your SSH key, and runs the command against a WP Engine environment over SSH Gateway. |
| `wp-cli.yml` | Optional alias mappings (only needed if an alias name should differ from the environment name). |

### Why a container
WP-CLI needs PHP; rather than installing PHP system-wide, everything runs in a
throwaway container. Your private SSH key is mounted read-only and copied into
the container at runtime with safe permissions — it never leaves your machine
and is never committed.

---

## 2. Authentication setup (one time per machine)

1. Generate a key if you don't have one:
   `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519`
2. Add the **public** key (`~/.ssh/id_ed25519.pub`) to the
   **WP Engine User Portal → User Settings → SSH Keys (SSH Gateway)**.
3. Make sure **SSH Gateway** is enabled on each environment you'll use.
4. (Optional) add to `~/.ssh/config`:
   ```
   Host *.ssh.wpengine.net
     IdentityFile ~/.ssh/id_ed25519
     IdentitiesOnly yes
   ```
5. Verify: `./wp <env> core version`

Check your key's fingerprint any time with:
`ssh-keygen -lf ~/.ssh/id_ed25519.pub` and compare to the portal listing.

### Gotchas discovered during setup
1. **WP-CLI's built-in `--ssh=` transport does not work with WP Engine's gateway** — it drops the hostname from the ssh invocation (`ssh -T -q wp ...`), so connections always fail. The `./wp` wrapper avoids this by ssh'ing directly and running WP Engine's own on-server `wp` binary.
2. **On-server WP root is `/sites/<env>`** (a symlink to `/nas/content/live/<env>`), not `/sites/<env>/public`.
3. **ssh rejects read-only/world-readable key & config files** — the wrapper copies them into the container and fixes permissions at startup.
4. WP Engine's remote `wp` is an older/slimmer build: e.g. `wp site info` has no `info` subcommand there (use `wp option get siteurl`, `wp core version`, etc.).

---

## 3. Usage

```bash
cd <this repo>

# Any WP-CLI command against an environment:
./wp <env> plugin list
./wp <env> option get siteurl
./wp <env> core version

# Interactive shell ON the WP Engine server (WP root):
./wp <env> shell

# WP-CLI inside the container only (no SSH):
./wp --local --help

# New environments work out of the box as `./wp <env-name> <command>`
# as long as your portal user's key has access and SSH Gateway is enabled.
```

### Handy commands

```bash
./wp <env> user list --fields=ID,user_login,roles
./wp <env> plugin list
./wp <env> theme list
./wp <env> db size --tables          # table sizes
./wp <env> option get siteurl
```

### Rebuilding / updating the image
```bash
docker build -t wpcli-wpe .
```
(The remote `wp` on WP Engine is managed by them; only the container's local copy is ours.)

---

## 4. Temporary user passwords

WordPress has no built-in expiry — "temporary" means *we rotate it back*.

```bash
# Generate a random strong password and set it (never commit the output):
PASS=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 4; tr -dc 'A-Za-z0-9!@#$%' </dev/urandom | head -c 12)
./wp <env> user update <user-id|login|email> --user_pass="$PASS"
echo "TEMP PASSWORD: $PASS"   # share over a secure channel, then forget it
```

Notes:
- WordPress sends the user a **"password changed" email** automatically — give them a heads-up.
- Rotate when done: re-run with a new password, or have the user hit **"Lost password"**.
- Optional cleanup — force logout everywhere else:
  ```bash
  ./wp <env> user remove-session-tokens <user-id>
  ```
- **Never write passwords, API keys or fingerprints into this repo.**

---

## 5. Environments

Record environment names and notes here (no secrets!):

| Environment | WP Engine name | URL | Notes |
|---|---|---|---|
| production | _(add)_ | _(add)_ | |
| staging | _(add)_ | _(add)_ | |

---

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| `Permission denied (publickey)` | Key not in User Portal (SSH Gateway section, not GitPush), SSH Gateway disabled for the env, or wrong env name. Compare `ssh-keygen -lf ~/.ssh/id_ed25519.pub` with the portal. |
| `Error: Cannot connect over SSH using provided configuration` | Only happens if you use `wp --ssh=` directly — always go through `./wp`. |
| `Bad owner or permissions on /root/.ssh/config` | Outdated wrapper; pull the current `./wp` script. |
| New environment unreachable | Confirm env name in User Portal, SSH Gateway enabled, and the portal user with your key has access to that env. |
| Image missing / broken | `docker build -t wpcli-wpe .` |
