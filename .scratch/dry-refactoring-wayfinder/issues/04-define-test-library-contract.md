# Define Test Library Contract

Type: grilling
Status: resolved
Blocked by: 01

## Question

What API and fixture conventions should the repository-local shell test library provide for argument validation, temporary roots, cleanup, rendered-script execution, and common assertions, and which command mocks must remain test-specific?

## Answer

`tests/test-helpers.sh` provides `test_require_args`, `test_setup`, `test_run_script`, and `test_assert_file_contains`. Tests use the shared argument/temp lifecycle and keep application-specific command mocks, fixtures, and process behavior local.
