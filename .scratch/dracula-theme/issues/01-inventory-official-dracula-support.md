# Inventory official Dracula support for the managed baseline

Type: research
Status: resolved

## Question

For every managed workstation application and developer-shell tool in the Ubuntu bootstrap baseline, which free official Dracula port exists, what channel distributes it, how is it activated, and what version or runtime prerequisites does it have? Identify unsupported applications explicitly and distinguish app theming from merely changing a terminal palette.

## Answer

The support matrix is recorded in [Official Dracula support inventory](../01-official-support.md). The confirmed implementation candidates are VS Code, Chrome, Slack, Obsidian, GTK/GNOME terminal palettes, tmux, FZF, Powerlevel10k, Git, ripgrep, and eza. Native Zsh support assumes Oh My Zsh and would replace the current Powerlevel10k architecture; zsh-syntax-highlighting requires a new utility; Spotify TUI is separate from Spotify desktop; and Claude Code is listed in the official catalog but lacked retrievable activation instructions.

No applicable free port was found for 1Password, Spotify desktop, diagrams.net Desktop, DBeaver, DevToys, Flameshot, AWS CLI, GitHub CLI, mise, zoxide, bat, .NET SDK, or native Discord. The GNOME Terminal and GTK ports make Ptyxis a candidate, not a confirmed target. Browser/profile, Slack account, Obsidian vault, GNOME desktop, and existing Powerlevel10k state require a separate ownership investigation.
