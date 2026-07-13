# Plan Migration and CI Slices

Type: grilling
Status: resolved
Blocked by: 02, 03, 04

## Question

In what order should the shared fragments and test library be introduced and adopted by script families, and what exact `.github/workflows/validate.yml` changes keep rendered output, `bash -n`, `shellcheck`, focused tests, and chezmoi dry-run verification as enforceable gates throughout the migration?

## Answer

The implementation introduced shell fragments first, migrated JSON consumers second, and migrated the shell-test suite third. CI now renders and validates the atomic Python fragment, shell-checks the test helper, keeps rendered-script syntax and focused tests, and invokes non-executable static tests through `bash`; local verification also runs chezmoi dry-run and `verify --exclude scripts`.
