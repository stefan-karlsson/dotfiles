#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 2 "$@"
slack_script="$1"
obsidian_script="$2"
company_slack_script="${test_root}/slack-company.sh"
private_obsidian_script="${test_root}/obsidian-private.sh"
sed 's/profile_name="default"/profile_name="company"/' "${slack_script}" > "${company_slack_script}"
sed 's/profile_name="default"/profile_name="private"/' "${obsidian_script}" > "${private_obsidian_script}"

mkdir -p \
  "${test_root}/bin" \
  "${test_root}/slack/storage" \
  "${test_root}/vault/.obsidian/themes/Dracula Official"

cat >"${test_root}/bin/git" <<'EOF'
#!/usr/bin/env bash
printf 'unexpected git clone\n' >&2
exit 1
EOF
chmod +x "${test_root}/bin/git"

cat >"${test_root}/bin/ps" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${test_root}/bin/ps"

cat >"${test_root}/slack/storage/root-state.json" <<'EOF'
{"settings":{"userTheme":"light","systemThemeSyncEnabled":true},"webapp":{"teams":{"T123":{"theme":{"titlebarBackground":"#350d36","titlebarTextColor":"#FFFFFF"}}}}}
EOF

cat >"${test_root}/vault/.obsidian/themes/Dracula Official/manifest.json" <<'EOF'
{"name":"Dracula Official"}
EOF
cat >"${test_root}/vault/.obsidian/themes/Dracula Official/theme.css" <<'EOF'
:root { --background-primary: #282a36; }
EOF
cat >"${test_root}/vault/.obsidian/appearance.json" <<'EOF'
{"cssTheme":"Obsidian","keep":true}
EOF

PATH="${test_root}/bin:${PATH}" \
  SLACK_CONFIG_DIR="${test_root}/slack" \
  bash "${company_slack_script}"
PATH="${test_root}/bin:${PATH}" \
  OBSIDIAN_SCAN_ROOT="${test_root}" \
  bash "${private_obsidian_script}"

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
