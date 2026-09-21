# AGENTS.md

This repo manages WP Engine WordPress environments with WP-CLI, run in a
Docker container over WP Engine's SSH Gateway.

## How to run commands

Always go through the wrapper script — never call `docker`, `ssh`, or `wp`
directly, and never use `wp --ssh=` (it is broken against WP Engine's gateway):

```bash
./wp <env> <wp-cli args...>     # run any WP-CLI command on the environment
./wp <env> shell                # interactive shell on the server (rarely useful for agents)
./wp --local --help             # WP-CLI inside the container only (no SSH)
```

`<env>` is the environment name from the WP Engine User Portal (the same name
used in `<env>.wpengine.com`). See NOTES.md § 5 for the list of known
environments.

## Prerequisites (already set up on the machine)

- Docker, with the `wpcli-wpe` image built (`docker build -t wpcli-wpe .` if missing)
- An ed25519 SSH key registered in the WP Engine User Portal → SSH Keys (SSH Gateway)
- SSH Gateway enabled per environment

## Rules

- **Read-only by default.** Prefer read commands (`plugin list`, `option get`,
  `user list`, `db size`, `core version`, ...). Before running anything that
  writes (`plugin activate/deactivate/update`, `option update`, `user update`,
  `db query`, `cache purge`, etc.), state exactly what it will change and get
  confirmation first.
- **Never output secrets.** Do not print private keys, passwords, or full
  `wp db` credentials. When generating a temporary password, show it once for
  the user to copy and never write it into a file in this repo.
- Remote WP root on the server is `/sites/<env>` (not `/sites/<env>/public`).
- The remote `wp` binary is older/slimmer than the container's: some
  subcommands don't exist there (e.g. `wp site info` — use
  `wp option get siteurl` / `wp core version` instead).
- Non-zero exit + `Permission denied (publickey)` → see NOTES.md § 6
  (troubleshooting) before retrying; don't retry blindly.

## More detail

`NOTES.md` is the full runbook: setup, gotchas discovered during setup,
handy commands, and a troubleshooting table. Read it when something fails.
