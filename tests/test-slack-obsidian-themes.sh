#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=fixture.sh
. "$(dirname -- "${BASH_SOURCE[0]}")/fixture.sh"
test_setup "$@"

slack_installer='home/.chezmoiscripts/run_always_after_25-configure-slack-theme.sh.tmpl'
obsidian_installer='home/.chezmoiscripts/run_always_after_26-configure-obsidian-theme.sh.tmpl'
slack_state="${test_root}/slack/storage/root-state.json"
appearance="${test_root}/vault/.obsidian/appearance.json"

mkdir -p \
  "${test_root}/slack/storage" \
  "${test_root}/vault/.obsidian/themes/Dracula Official"

# The theme directory is already present, so a clone means the installer looked
# in the wrong place.
test_stub_command git 'printf "unexpected git clone\n" >&2; exit 1'
# No Slack or Obsidian process is running.
test_stub_command ps 'exit 0'

cat >"${slack_state}" <<'EOF'
{"settings":{"userTheme":"light","systemThemeSyncEnabled":true},"webapp":{"teams":{"T123":{"theme":{"titlebarBackground":"#350d36","titlebarTextColor":"#FFFFFF"}}}}}
EOF

cat >"${test_root}/vault/.obsidian/themes/Dracula Official/manifest.json" <<'EOF'
{"name":"Dracula Official"}
EOF
cat >"${test_root}/vault/.obsidian/themes/Dracula Official/theme.css" <<'EOF'
:root { --background-primary: #282a36; }
EOF
cat >"${appearance}" <<'EOF'
{"cssTheme":"Obsidian","keep":true}
EOF

configure_slack() {
  local profile="$1"

  SLACK_CONFIG_DIR="${test_root}/slack" \
    test_run_script "$(test_render_template "${slack_installer}" "${profile}")"
}

# Each Obsidian case owns the root it is scanned under, so a vault one case
# creates is never discovered by another. The shared vault above is reached
# through its own directory rather than through the whole temporary root.
configure_obsidian_under() {
  local scan_root="$1"
  local profile="$2"

  OBSIDIAN_SCAN_ROOT="${scan_root}" \
    test_run_script "$(test_render_template "${obsidian_installer}" "${profile}")"
}

configure_obsidian() {
  local profile="$1"

  configure_obsidian_under "${test_root}/vault" "${profile}"
}

assert_unchanged() {
  local file="$1"
  local reference="$2"

  cmp -s "${file}" "${reference}" || {
    printf '%s was modified when it should have been left alone\n' "${file}" >&2
    return 1
  }
}

stub_successful_clone() {
  test_stub_command git - <<'STUB'
target="${*: -1}"
mkdir -p "${target}"
printf '{"name":"Dracula Official"}\n' >"${target}/manifest.json"
printf ':root { --background-primary: #282a36; }\n' >"${target}/theme.css"
STUB
}

stub_refused_clone() {
  test_stub_command git 'printf "unexpected git clone\n" >&2; exit 1'
}

# An Orca worktree of the vault repository carries an empty theme directory,
# because inside the vault the theme is a nested clone. Nothing is lost by
# replacing it, so the installer clones over it instead of refusing.
empty_theme_root="${test_root}/empty-theme"
empty_theme_dir="${empty_theme_root}/vault/.obsidian/themes/Dracula Official"
mkdir -p "${empty_theme_dir}"
cat >"${empty_theme_root}/vault/.obsidian/appearance.json" <<'EOF'
{"cssTheme":"Obsidian"}
EOF
test_reset_calls
stub_successful_clone
configure_obsidian_under "${empty_theme_root}" private
test_assert_called "clone --depth 1 https://github.com/dracula/obsidian.git ${empty_theme_dir}"
test_assert_file_contains '"cssTheme": "Dracula Official"' \
  "${empty_theme_root}/vault/.obsidian/appearance.json"

# A theme directory holding something the installer does not recognise is an
# error, not something to clone over: it may be content nobody else will put
# back.
incomplete_theme_root="${test_root}/incomplete-theme"
incomplete_theme_dir="${incomplete_theme_root}/vault/.obsidian/themes/Dracula Official"
mkdir -p "${incomplete_theme_dir}"
cat >"${incomplete_theme_dir}/manifest.json" <<'EOF'
{"name":"Dracula Official"}
EOF
cat >"${incomplete_theme_root}/vault/.obsidian/appearance.json" <<'EOF'
{"cssTheme":"Obsidian"}
EOF
cp "${incomplete_theme_root}/vault/.obsidian/appearance.json" \
  "${test_root}/incomplete-appearance.seeded"
test_reset_calls
stub_refused_clone
# The installer is expected to fail here, so errexit is lifted for that one
# call and restored immediately after it.
set +e
configure_obsidian_under "${incomplete_theme_root}" private \
  >"${test_root}/incomplete.out" 2>&1
incomplete_status=$?
set -e
((incomplete_status != 0)) || {
  printf 'the installer accepted an incomplete theme directory: %s\n' \
    "${incomplete_theme_dir}" >&2
  exit 1
}
test_assert_file_contains \
  "Obsidian Dracula theme directory is incomplete: ${incomplete_theme_dir}" \
  "${test_root}/incomplete.out"
test_assert_not_called clone
assert_unchanged "${incomplete_theme_root}/vault/.obsidian/appearance.json" \
  "${test_root}/incomplete-appearance.seeded"

# Orca worktrees are temporary, and each one would otherwise be handed its own
# copy of the theme, so the scan never descends into them.
orca_root="${test_root}/orca-scan"
mkdir -p "${orca_root}/orca/workspaces/feature/vault/.obsidian"
cat >"${orca_root}/orca/workspaces/feature/vault/.obsidian/appearance.json" <<'EOF'
{"cssTheme":"Obsidian"}
EOF
cp "${orca_root}/orca/workspaces/feature/vault/.obsidian/appearance.json" \
  "${test_root}/orca-appearance.seeded"
test_reset_calls
stub_refused_clone
configure_obsidian_under "${orca_root}" private >"${test_root}/orca-scan.out"
test_assert_file_contains 'No Obsidian vault configuration folders found' \
  "${test_root}/orca-scan.out"
test_assert_not_called clone
assert_unchanged "${orca_root}/orca/workspaces/feature/vault/.obsidian/appearance.json" \
  "${test_root}/orca-appearance.seeded"

# The cases below share the vault seeded above, where the theme directory is
# already complete, so a clone means the installer looked in the wrong place.
test_reset_calls
stub_refused_clone

# The Slack theme belongs to one profile overlay, so under the others the
# installer must leave Slack's state alone. Obsidian has no profile gate: the
# vault is configured under every profile, so each one must theme it.
cp "${slack_state}" "${test_root}/slack-state.seeded"
for profile in default private; do
  configure_slack "${profile}"
  assert_unchanged "${slack_state}" "${test_root}/slack-state.seeded"
done
for profile in default company; do
  # The vault is reset to its unthemed seed first, so every profile genuinely
  # exercises the configure path rather than inheriting the previous result.
  cat >"${appearance}" <<'EOF'
{"cssTheme":"Obsidian","keep":true}
EOF
  configure_obsidian "${profile}"
  test_assert_file_contains '"cssTheme": "Dracula Official"' "${appearance}"
done

configure_slack company
configure_obsidian private

python3 - "${test_root}" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
slack = json.loads((root / "slack/storage/root-state.json").read_text())
assert slack["settings"] == {"userTheme": "dark", "systemThemeSyncEnabled": False}
assert slack["webapp"]["teams"]["T123"]["theme"] == {
    "titlebarBackground": "#282A36",
    "titlebarTextColor": "#F8F8F2",
}

appearance = json.loads((root / "vault/.obsidian/appearance.json").read_text())
assert appearance == {"cssTheme": "Dracula Official", "keep": True}
assert (root / "vault/.obsidian/themes/Dracula Official/theme.css").is_file()
assert list((root / "slack/storage").glob("root-state.json.chezmoi-backup.*"))
assert list((root / "vault/.obsidian").glob("appearance.json.chezmoi-backup.*"))
PY

printf 'Slack and Obsidian Dracula theme checks passed\n'
