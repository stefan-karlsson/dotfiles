# Choose the theme asset and update strategy

Type: grilling
Status: resolved
Blocked by: 03

## Question

For the supported settings that chezmoi will own, should assets be vendored, pinned to explicit upstream releases, or refreshed from official sources at apply time, and how should changes be detected so bootstrap remains idempotent while theme updates are intentional and reviewable?

## Answer

Use official free distribution channels at apply time rather than vendoring paid or
opaque artifacts. The GTK and tmux repositories are cloned or fast-forwarded from the
Dracula organization under `~/.local/share`; existing non-git targets, origin changes,
local modifications, and non-fast-forward updates fail clearly. VS Code installs the
official Marketplace extension, and Chrome uses the official Web Store update URL with
the exact theme ID from Dracula's Chrome page. Source-managed shell and application
settings are changed through chezmoi templates. This keeps updates reproducible in
origin and behavior while allowing upstream theme fixes without manual downloads.
