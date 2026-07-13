#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=test-helpers.sh
. "$(dirname "${BASH_SOURCE[0]}")/test-helpers.sh"
test_setup 1 "$@"
wrapper="$1"

mkdir -p "$test_root/bin"
cat > "$test_root/bin/flameshot" <<'EOF'
#!/usr/bin/env bash
printf 'platform=%s args=%s\n' "${QT_QPA_PLATFORM:-unset}" "$*"
EOF
chmod +x "$test_root/bin/flameshot"

wayland_output="$(
  PATH="$test_root/bin:$PATH" \
  XDG_SESSION_TYPE=wayland \
  bash "$wrapper" --test
)"
[[ "$wayland_output" == 'platform=wayland args=gui --test' ]]

x11_output="$(
  PATH="$test_root/bin:$PATH" \
  XDG_SESSION_TYPE=x11 \
  bash "$wrapper" --test
)"
[[ "$x11_output" == 'platform=unset args=gui --test' ]]
