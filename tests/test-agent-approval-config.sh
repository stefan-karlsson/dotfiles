#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

# Claude Code enrols safe commands by rule, so the settings file is checked for
# the rules that carry the policy rather than for every entry it lists.
settings="$(test_render_template 'home/dot_claude/modify_settings.json')"

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
assert_absent 'Bash(npx:*)' "$settings"
assert_absent 'Bash(npx *)' "$settings"
assert_absent 'Bash(curl' "$settings"
assert_absent 'Bash(kubectl' "$settings"

# Codex has no allowlist to check. Its prompting is the named permission set and
# the approval policy, which is what the configuration states.
codex="$(test_render_template 'home/dot_codex/modify_config.toml')"

test_assert_file_contains 'default_permissions = "twg-workspace"' "$codex"
test_assert_file_contains 'approval_policy = "on-request"' "$codex"

# The set the default name resolves to grants the workspace, the network, and
# the two paths TWG writes to, and nothing wider.
test_assert_file_contains 'extends = ":workspace"' "$codex"
test_assert_file_contains 'enabled = true' "$codex"
test_assert_file_contains '/.config/twg" = "write"' "$codex"
test_assert_file_contains '/.local/bin" = "write"' "$codex"

# The permission set is what makes an unprompted command safe, and the
# escalation prompt is the one approval Codex asks for.
assert_absent 'danger-full-access' "$codex"
assert_absent ':full-access' "$codex"
assert_absent 'approval_policy = "never"' "$codex"
