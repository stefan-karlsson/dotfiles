# Plan Migration and CI Slices

Type: grilling
Status: resolved
Blocked by: 02, 03, 04

## Question

In what order should the shared fragments and test library be introduced and adopted by script families, and what exact `.github/workflows/validate.yml` changes keep rendered output, `bash -n`, `shellcheck`, focused tests, and chezmoi dry-run verification as enforceable gates throughout the migration?

## Answer

The implementation introduced shell fragments first, migrated JSON consumers second, and migrated the shell-test suite third. CI now renders and validates the atomic Python fragment, shell-checks the test helper, keeps rendered-script syntax and focused tests, and invokes non-executable static tests through `bash`; local verification also runs chezmoi dry-run and `verify --exclude scripts`.

## Comments

Superseded 2026-08-04 by candidate 2 of the architecture review. The gates are
unchanged in kind, but the inventory is no longer hand-listed in
`validate.yml`: `tests/lint-sources.sh` discovers every program in the source
tree and renders it under every Bootstrap profile (and under none), then applies
`bash -n`, `shellcheck`, `py_compile`, or `zsh -n`; `tests/run-tests.sh` runs
every `tests/test-*.sh`. A source in an unrecognised location fails the pass
rather than going unchecked.

The hand-maintained list is what let `run_always_after_28-configure-dash-to-dock`
and `run_always_after_29-configure-gnome-favorites` fall out of CI entirely.
