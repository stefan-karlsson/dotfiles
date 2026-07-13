# Decide which supported theme state chezmoi owns

Type: grilling
Status: resolved
Blocked by: 01, 02

## Question

Given the support matrix and persistence boundaries, which supported applications and theme settings should be actively owned by chezmoi after bootstrap, and which should receive only an installable asset or documented manual step because ownership would cross an account, profile, workspace, or vault boundary?

## Answer

Chezmoi owns the free Dracula theme for VS Code, Chrome, GTK/Ptyxis, tmux, FZF,
Powerlevel10k, Git, ripgrep, eza, Slack, and existing Obsidian vault profiles. Chrome
profile theme selection is explicitly within scope because the user requested the
lowest-manual-workflow option; the rest of each profile is preserved and backed up.
Slack and Obsidian settings are updated only in already-existing local profiles/vaults,
with unrelated workspace and note data preserved. The existing
Powerlevel10k layout is preserved while its palette is changed. Zsh's Oh My Zsh port,
zsh-syntax-highlighting, Spotify TUI, and Claude Code are not added because they would
introduce a new architecture, dependency, or unresolved activation path.
