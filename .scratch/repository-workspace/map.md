# Repository workspace

## Destination

Configure an Ubuntu repository workspace rooted at `~/repos`, with the initial GitHub namespace `~/repos/github/stefan-karlsson`, documented and created idempotently by chezmoi. VS Code should trust only that personal namespace while preserving existing trust decisions.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `chezmoi`, `grilling`, `domain-modeling`, and `wayfinder` skills. The reference repository contributed the dedicated repository-root and host/owner layout ideas; this effort keeps cloning and repository contents unmanaged.

Agreed constraints: keep the chezmoi source at `~/.local/share/chezmoi`; create the directory tree without `sudo`; support Ubuntu only; use `~/repos/<host>/<owner>/<repository>` for future namespaces; do not automate cloning; fail clearly if managed VS Code is unavailable; refuse trust-store writes while VS Code is running; update trust storage atomically and retain the three newest backups.

## Decisions so far

- [Validate VS Code trust-store provisioning](./issues/01-validate-vscode-trust-storage.md) — merge the personal namespace into VS Code's machine-scoped trust record with atomic writes, three rotating backups, and safe process checks.

## Not yet specified

<!-- The route to the destination is clear; future VS Code format changes may require a new map. -->

## Out of scope

- Moving the chezmoi source repository.
- Automatically cloning, synchronizing, or migrating repositories.
- Trusting all of `~/repos` or third-party repository namespaces.
- Supporting non-Ubuntu machines in this effort.
