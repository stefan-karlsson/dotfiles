---
name: chezmoi
description: Safely manage this chezmoi dotfiles repository, including source-state files, templates, package data, install scripts, machine-specific configuration, and verification. Use when working in this dotfiles repository or when a task changes its chezmoi-managed configuration.
---

# Chezmoi maintenance

Treat `home/` as the source state; the repository root is the Git working tree because `.chezmoiroot` selects `home/`.

## Workflow

1. Inspect the current target and source state with `chezmoi status`, `chezmoi diff`, `chezmoi cat <target>`, and `chezmoi source-path <target>`.
2. Make the smallest source-state change. Use templates only for genuine machine variation and keep installation scripts idempotent.
3. Render and review templated output before applying. Use `chezmoi apply --dry-run --verbose` for broader changes.
4. Run `chezmoi apply` without `--force` by default, then `chezmoi verify`.
5. Commit only public-safe source state. Never add private keys, tokens, passwords, or Codex state.

## Repository conventions

- Declare Ubuntu packages and external tool pins in `.chezmoidata/packages.toml`.
- Put apply-time actions in `.chezmoiscripts/` using `run_onchange_` and `before_` or `after_` only when ordering is required.
- Use `dot_`, `private_`, `executable_`, and `.tmpl` source attributes deliberately. `private_` removes group and world permissions; it is not encryption.
- Keep macOS additions behind `.chezmoi.os == "darwin"` and the reserved Darwin package data until a macOS bootstrap is implemented.
- Use `--refresh-externals` only when changing or intentionally refreshing an external dependency. Use `--force` only after reviewing an overwrite and receiving explicit direction.

## Validation

Run `shellcheck install.sh`, render or dry-run changed templates, run `chezmoi verify`, and keep the Ubuntu 26.04 CI workflow passing.
