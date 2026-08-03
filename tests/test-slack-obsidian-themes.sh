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

configure_obsidian() {
  local profile="$1"

  OBSIDIAN_SCAN_ROOT="${test_root}" \
    test_run_script "$(test_render_template "${obsidian_installer}" "${profile}")"
}

assert_unchanged() {
  local file="$1"
  local reference="$2"

  cmp -s "${file}" "${reference}" || {
    printf '%s was modified when it should have been left alone\n' "${file}" >&2
    return 1
  }
}

# Each theme belongs to one profile overlay; under the others the installer must
# leave the application's state alone.
cp "${slack_state}" "${test_root}/slack-state.seeded"
cp "${appearance}" "${test_root}/appearance.seeded"
for profile in default private; do
  configure_slack "${profile}"
  assert_unchanged "${slack_state}" "${test_root}/slack-state.seeded"
done
for profile in default company; do
  configure_obsidian "${profile}"
  assert_unchanged "${appearance}" "${test_root}/appearance.seeded"
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
