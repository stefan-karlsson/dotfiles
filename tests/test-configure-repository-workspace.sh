#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_require_args 1 "$@"
workspace_script="$1"
test_home="$(mktemp -d)"
fake_bin="$test_home/bin"
namespace="$test_home/repos/github/stefan-karlsson"
storage_file="$test_home/.config/Code/User/globalStorage/storage.json"
cleanup() {
  rm -rf "$test_home"
}
trap cleanup EXIT

mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$fake_bin/code"
printf '%s\n' '#!/usr/bin/env bash' '[[ "${FAKE_CODE_RUNNING:-0}" == 1 ]]' > "$fake_bin/pgrep"
chmod +x "$fake_bin/code" "$fake_bin/pgrep"

run_workspace_script() {
  HOME="$test_home" \
    XDG_CONFIG_HOME="$test_home/.config" \
    PATH="$fake_bin:/usr/bin:/bin" \
    FAKE_CODE_RUNNING="${FAKE_CODE_RUNNING:-0}" \
    bash "$workspace_script"
}

run_workspace_script
[[ -d "$namespace" ]]
[[ -f "$storage_file" ]]

python3 - "$storage_file" "$namespace" <<'PY'
import json
import sys

storage_path, namespace = sys.argv[1:]
with open(storage_path, encoding="utf-8") as storage_file:
    storage = json.load(storage_file)
trust = json.loads(storage["content.trust.model.key"])
paths = {entry["uri"]["path"] for entry in trust["uriTrustInfo"] if entry["trusted"]}
assert paths == {namespace}
PY

python3 - "$storage_file" "$namespace" <<'PY'
import json
import sys

storage_path, namespace = sys.argv[1:]
with open(storage_path, encoding="utf-8") as storage_file:
    storage = json.load(storage_file)
trust = json.loads(storage["content.trust.model.key"])
trust["uriTrustInfo"].append({
    "uri": {"scheme": "file", "authority": "", "path": "/trusted/elsewhere", "query": "", "fragment": ""},
    "trusted": True,
})
for entry in trust["uriTrustInfo"]:
    if entry["uri"]["path"] == namespace:
        entry["trusted"] = False
storage["content.trust.model.key"] = json.dumps(trust)
with open(storage_path, "w", encoding="utf-8") as storage_file:
    json.dump(storage, storage_file, indent=4)
    storage_file.write("\n")
PY

for backup_number in 1 2 3; do
  printf 'existing backup %s\n' "$backup_number" > "$storage_file.chezmoi-backup.$backup_number"
done
run_workspace_script

backup_count="$(find "$(dirname "$storage_file")" -maxdepth 1 -type f -name 'storage.json.chezmoi-backup.*' | wc -l)"
[[ "$backup_count" -le 3 ]]
python3 - "$storage_file" "$namespace" <<'PY'
import json
import sys

storage_path, namespace = sys.argv[1:]
with open(storage_path, encoding="utf-8") as storage_file:
    storage = json.load(storage_file)
trust = json.loads(storage["content.trust.model.key"])
paths = {entry["uri"]["path"] for entry in trust["uriTrustInfo"] if entry["trusted"]}
assert paths == {namespace, "/trusted/elsewhere"}
PY

run_workspace_script
backup_count_after_idempotent_run="$(find "$(dirname "$storage_file")" -maxdepth 1 -type f -name 'storage.json.chezmoi-backup.*' | wc -l)"
[[ "$backup_count_after_idempotent_run" == "$backup_count" ]]

running_home="$(mktemp -d)"
if HOME="$running_home" XDG_CONFIG_HOME="$running_home/.config" PATH="$fake_bin:/usr/bin:/bin" FAKE_CODE_RUNNING=1 bash "$workspace_script" >"$running_home/output" 2>&1; then
  printf 'error: workspace script modified trust storage while VS Code was running\n' >&2
  exit 1
fi
grep -Fq 'VS Code is running' "$running_home/output"
[[ ! -e "$running_home/repos" ]]
rm -rf "$running_home"

rm "$fake_bin/code"
missing_code_home="$(mktemp -d)"
if HOME="$missing_code_home" XDG_CONFIG_HOME="$missing_code_home/.config" PATH="$fake_bin" /bin/bash "$workspace_script" >"$missing_code_home/output" 2>&1; then
  printf 'error: workspace script accepted a missing VS Code installation\n' >&2
  exit 1
fi
grep -Fq 'VS Code is unavailable' "$missing_code_home/output"
[[ ! -e "$missing_code_home/repos" ]]
rm -rf "$missing_code_home"

printf 'repository workspace and VS Code trust tests passed\n'
