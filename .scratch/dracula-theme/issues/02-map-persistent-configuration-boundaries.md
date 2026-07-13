# Map persistent configuration boundaries for supported applications

Type: research
Status: resolved
Blocked by: 01

## Question

For each application identified as supported by `Inventory official Dracula support for the managed baseline`, where does its theme state persist on Ubuntu, which parts are global versus account/profile/workspace/vault scoped, and what merge or process-safety rules are needed for chezmoi to activate Dracula without losing existing user settings?

## Answer

The implementation separates source-owned settings from application-owned state:

- VS Code's theme setting is merged through `modify_settings.json`; the Dracula extension is installed by the existing extension script. Workspace trust remains separately managed.
- Chrome's official Web Store theme is registered through Chrome's supported Linux external-extension directory. Existing `Default` and `Profile *` `Preferences` files are updated atomically after a process check, with up to three backups; System and Guest profiles are skipped.
- GTK/GNOME and the default Ptyxis profile are desktop-wide or profile settings, so the apply script checks the actual Ptyxis schema and fails clearly when it cannot set the palette.
- tmux, FZF, Powerlevel10k, Git, ripgrep, and eza persist in source-managed configuration files or an official theme checkout and are safe to own.
- Slack remains account/workspace scoped, and Obsidian remains vault scoped; both are documented manual steps. Unsupported applications are untouched.
