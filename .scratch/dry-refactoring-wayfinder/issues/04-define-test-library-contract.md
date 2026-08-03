# Define Test Library Contract

Type: grilling
Status: resolved
Blocked by: 01

## Question

What API and fixture conventions should the repository-local shell test library provide for argument validation, temporary roots, cleanup, rendered-script execution, and common assertions, and which command mocks must remain test-specific?

## Answer

`tests/test-helpers.sh` provides `test_require_args`, `test_setup`, `test_run_script`, and `test_assert_file_contains`. Tests use the shared argument/temp lifecycle and keep application-specific command mocks, fixtures, and process behavior local.

## Comments

Superseded 2026-08-04 by candidate 2 of the architecture review ("Put a seam
between the rendered script and its test"). The library is now
`tests/fixture.sh`, and the contract is an interface rather than four helpers:
`script + profile → executable + call log`.

- `test_render_template <source-path> [profile]` renders a source template under
  a named Bootstrap profile, so a profile overlay is a test argument instead of a
  `sed` rewrite of rendered text. `test_source_file` names a source read verbatim.
- `test_setup` takes no arguments: a test names its own inputs rather than
  receiving a rendered path from CI. It also owns the exit path, which tests
  extend through `test_on_exit` instead of replacing the trap.
- `test_stub_command` installs a command stub on one shared PATH and records
  every call, with `test_assert_called` / `test_assert_not_called` /
  `test_reset_calls` reading the log.

The decision that application-specific command mocks stay local still holds: a
stub's *body* is written by the test. What moved into the module is the stub
directory, the call log, and the rendering.

A handful of tests still mock with `export -f` rather than a stub, because their
fakes delegate to the real command (`command dpkg "$@"`) or shadow a shell
builtin — neither of which a same-named executable on PATH can do. Those are
`test-configure-docker.sh`, `test-configure-docker-desktop.sh`,
`test-ensure-sudo-group.sh`, `test-enable-kvm.sh`, `test-initialize-pass.sh`,
`test-update-matt-pocock-skills.sh`, `test-verify-1password-setup.sh`, and
`test-install-ubuntu-packages.sh`.
