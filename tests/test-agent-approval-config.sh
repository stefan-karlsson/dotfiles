#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

# Claude Code enrols safe commands by rule, so the settings file is checked for
# the rules that carry the policy rather than for every entry it lists.
settings="$(test_render_template 'home/dot_claude/settings.json.tmpl')"

jq -e . "$settings" >/dev/null

test_assert_file_contains '"Bash(git status:*)"' "$settings"
test_assert_file_contains '"Bash(git diff:*)"' "$settings"
test_assert_file_contains '"Bash(git commit:*)"' "$settings"
test_assert_file_contains '"Bash(rg:*)"' "$settings"
test_assert_file_contains '"Bash(dotnet build:*)"' "$settings"
test_assert_file_contains '"Bash(dotnet test:*)"' "$settings"
test_assert_file_contains '"Bash(npm run:*)"' "$settings"
test_assert_file_contains '"Bash(make:*)"' "$settings"
test_assert_file_contains '"Bash(glab mr view:*)"' "$settings"

# The user preferences the file already carried are still owned by it, so
# managing permissions here does not silently drop them.
test_assert_file_contains '"theme": "dark"' "$settings"
test_assert_file_contains '"tui": "fullscreen"' "$settings"

# An absolute deny path follows the home directory of the machine applying it
# rather than the one it was authored on.
test_assert_file_contains "Read(//${HOME#/}/.ssh/**)" "$settings"
test_assert_file_contains "Read(//${HOME#/}/.aws/credentials)" "$settings"

test_assert_file_contains '"Bash(sudo:*)"' "$settings"
test_assert_file_contains '"Bash(snowsql:*)"' "$settings"

# Publishing, discarding, and destroying stay approvals. These are the commands
# an allowlist must not quietly absorb, so their absence is asserted rather than
# left to review.
assert_absent() {
  local rule="$1"
  local file="$2"

  if grep -Fq -- "${rule}" "${file}"; then
    printf '%s must stay an approval, but %s enrols it\n' "${rule}" "${file}" >&2
    return 1
  fi
}

assert_absent 'Bash(git push' "$settings"
assert_absent 'Bash(git reset' "$settings"
assert_absent 'Bash(git checkout' "$settings"
assert_absent 'Bash(git clean' "$settings"
assert_absent 'Bash(git rebase' "$settings"
assert_absent 'Bash(rm' "$settings"
assert_absent 'Bash(npx' "$settings"
assert_absent 'Bash(curl' "$settings"
assert_absent 'Bash(kubectl' "$settings"

# Codex has no allowlist to check: its prompting is the sandbox and approval
# pair, so that pair is what the configuration has to state.
codex="$(test_source_file 'home/dot_codex/config.toml')"

test_assert_file_contains 'sandbox_mode = "workspace-write"' "$codex"
test_assert_file_contains 'approval_policy = "on-request"' "$codex"
test_assert_file_contains 'network_access = true' "$codex"
test_assert_file_contains 'writable_roots = []' "$codex"

# danger-full-access would remove the sandbox that makes unprompted commands
# safe, and "never" would drop the escalation prompt that remains the only
# approval Codex still asks for.
assert_absent 'sandbox_mode = "danger-full-access"' "$codex"
assert_absent 'approval_policy = "never"' "$codex"
