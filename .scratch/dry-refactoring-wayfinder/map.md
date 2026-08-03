# DRY Refactoring Map

## Destination

An implementation-ready refactoring plan for reducing duplicated cross-cutting behavior in the chezmoi source state and its shell-test suite, with explicit helper contracts, migration order, and verification criteria.

## Notes

Domain: the single-context Dotfiles repository and its managed Ubuntu desktop environment.

Consult the `chezmoi`, `domain-modeling`, and `grilling` skills when working tickets. Preserve chezmoi's standalone rendered apply scripts: source-state fragments are included at render time, while test helpers are sourced only by repository tests.

Standing decisions from charting:

- Cover both apply scripts and tests, but extract repository-wide policies and test-harness behavior rather than domain-specific operations.
- Use small semantic fragments with explicit contracts, not one universal shell library.
- Share safe JSON file mechanics while keeping application-specific schema mutation local.
- Preserve behavior and keep rendered scripts as the primary test boundary.
- Migrate incrementally and update CI alongside each migration; no compatibility shims are required for internal helper names.

## Decisions so far

<!-- Closed child tickets are appended here as they resolve. -->

- [Inventory and Classify Shared Behavior](issues/01-inventory-and-classify-shared-behavior.md) — Extracted generic shell policy, GNOME settings policy, atomic JSON file safety, and test lifecycle seams; kept domain operations and mocks local.
- [Define Apply-Time Fragment Contracts](issues/02-define-apply-fragment-contracts.md) — Render-time `shell-foundation.sh` and `gnome-settings-foundation.sh` fragments preserve standalone scripts and shellcheckable output.
- [Define Safe JSON File Mechanics](issues/03-define-safe-json-file-mechanics.md) — `atomic-json-state.py` now centralizes symlink checks, JSON loading, permissions, bounded backups, atomic replacement, and cleanup for four application state consumers.
- [Define Test Library Contract](issues/04-define-test-library-contract.md) — `tests/test-helpers.sh` owns argument validation, temporary roots, rendered-script execution, and file-content assertions; command mocks remain local.
- [Plan Migration and CI Slices](issues/05-plan-migration-and-ci-slices.md) — The migration is complete in semantic slices, with rendering, syntax, shellcheck, Python compilation, focused tests, and chezmoi verification retained as gates.
- Superseding 04 and 05 (2026-08-04) — the test library became `tests/fixture.sh`, a seam of `script + profile → executable + call log`, and CI's inventory is now discovered from the source tree by `tests/lint-sources.sh` and `tests/run-tests.sh` rather than hand-listed. See the Comments sections of both tickets.

## Not yet specified

<!-- No in-scope decisions remain unspecified for this implementation. -->

## Out of scope

- Refactoring domain-specific installation or configuration operations merely because they use similar shell syntax.
- Sharing application-specific JSON schema mutations between Chrome, Slack, and Obsidian.
- Introducing runtime dependencies on the chezmoi source tree or a generated helper file.
