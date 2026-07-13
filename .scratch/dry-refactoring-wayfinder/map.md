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

## Not yet specified

- The exact inventory of duplicated behaviors and the final keep/extract classification.
- The names, locations, interfaces, and shell-safety rules for each shared apply-time fragment.
- The interface and fixture model for the shared test library, including which mocks can be generalized.
- The concrete migration slices across script families and the required CI changes for each slice.

## Out of scope

- Refactoring domain-specific installation or configuration operations merely because they use similar shell syntax.
- Sharing application-specific JSON schema mutations between Chrome, Slack, and Obsidian.
- Introducing runtime dependencies on the chezmoi source tree or a generated helper file.
