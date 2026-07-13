# Validate VS Code trust-store provisioning

Type: research
Status: resolved

## Question

What machine-local VS Code storage path and JSON shape should the chezmoi updater use on the managed Ubuntu installation, and how can it add `~/repos/github/stefan-karlsson` without losing existing trust entries or being overwritten by a running VS Code process?

## Answer

Use the Ubuntu VS Code Stable user-data path `${XDG_CONFIG_HOME:-$HOME/.config}/Code/User/globalStorage/storage.json` and merge the `content.trust.model.key` JSON payload's `uriTrustInfo` list with a trusted `file` URI for `~/repos/github/stefan-karlsson`. The updater creates the repository namespace first, preserves existing entries, rewrites the storage file atomically, retains the three newest timestamped backups, and refuses to proceed when `code` is unavailable or a `code` process is running. The behavior is covered by `tests/test-configure-repository-workspace.sh` and the complete rendered fixture suite.
