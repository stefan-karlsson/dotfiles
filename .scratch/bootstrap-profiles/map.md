# Profile-aware workstation bootstrap

## Destination

Produce an implementation-ready plan for explicit `private` and `company` bootstrap profiles in this Ubuntu chezmoi repository. Every bootstrap applies the shared default profile, an explicitly selected overlay adds its application set, and the overlay's identity-sensitive configuration is collected interactively and persisted locally without storing secrets in the public repository.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `wayfinder`, `chezmoi`, `grilling`, and `domain-modeling` skills. Keep the source state public-safe, use the existing package-data and apply-time script conventions, and preserve the current non-destructive migration behavior.

Agreed direction:

- The default profile always applies; `private` and `company` are explicit optional overlays.
- Profile selection is explicit and persisted locally; switching profiles is an explicit migration operation and never inferred from the machine.
- Overlays add or update their owned state and never automatically uninstall applications or delete prior identity configuration.
- Overlay application sets are committed allowlists; identity-sensitive values are collected by bootstrap or an explicit profile-configuration command, then reused by non-interactive `chezmoi apply`.
- Actual credentials, tokens, private keys, and account data remain outside the public repository; profile configuration may use public-safe metadata and 1Password references.

## Decisions so far

<!-- Closed tickets are appended here as the route advances. -->

- [Define profile selection and lifecycle](./issues/01-define-profile-selection-and-lifecycle.md) — `install.sh` selects and transactionally switches `default`, `private`, or `company`; the normalized profile is persisted locally and direct `chezmoi apply` uses it without overrides.

## Not yet specified

- Which existing managed packages, applications, and configuration belong in the default profile versus the private and company overlays.
- The complete interactive identity-input schema, including Git, repository, SSH/GitHub, and 1Password-related values.
- Which source-state files and apply-time actions need profile-aware ownership, and how missing or incompatible profile data fails safely.
- The upgrade path for existing machines with the current single-profile personal configuration.
- The deterministic rendered checks, local smoke checks, and documentation needed to prove profile isolation and non-destructive switching.

## Out of scope

- Automatic private/company machine detection.
- Storing credentials, tokens, private keys, or account data in the repository.
- Automatically uninstalling applications or deleting configuration when changing profiles.
- Supporting non-Ubuntu platforms in this effort.
- Implementing the profile system during charting; execution begins only after the implementation-ready plan is complete.
