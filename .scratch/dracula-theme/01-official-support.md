# Official Dracula support inventory

Researched 2026-07-13 for the Ubuntu bootstrap baseline in `home/.chezmoidata/packages.toml`, the managed Developer Shell, and the configured Ptyxis/VS Code environment.

## Classification

“Supported” below means that the free Dracula catalog has a page or repository for the application/tool. The catalog notes that many ports are community contributions, so the source and activation mechanism still need to be reviewed before chezmoi owns the state. Dracula Pro is excluded.

## Supported or plausible targets

| Managed application/tool | Free port and channel | Activation/prerequisites | Scope caveat |
| --- | --- | --- | --- |
| VS Code Stable | `Dracula Official` extension through the VS Code Marketplace; [official instructions](https://draculatheme.com/visual-studio-code) | Install the extension, then set the Color Theme to Dracula. | User settings and extension installation are separate state. |
| Google Chrome Stable | Chrome Web Store theme; [official instructions](https://draculatheme.com/google-chrome) | Install the theme through the Chrome Web Store. | Browser-profile state; requires deciding whether chezmoi may mutate the profile. |
| Slack | Built-in custom-theme palette; [official instructions](https://draculatheme.com/slack) | Set dark mode, then import `#282A36, #44475A, #50FA7B, #FF5555` in Preferences → Theme → Custom theme. | Account/workspace state, not a local global config. |
| Obsidian | `Dracula Official` community theme; [official instructions](https://draculatheme.com/obsidian) | Install from Appearance → Themes → Manage → Community themes, then activate it. | Theme is vault-scoped; the repo's vaults are intentionally unmanaged. |
| GTK desktop | Dracula GTK theme from the official Dracula page/repository; [official instructions](https://draculatheme.com/gtk) | Install under `~/.themes` or `/usr/share/themes`; activate with GNOME `gsettings`. GTK4/libadwaita needs additional assets under `~/.config`. | A desktop-wide GTK preference affects more than one application and needs an explicit ownership decision. |
| GNOME Terminal palette | `dracula/gnome-terminal`; [official instructions](https://draculatheme.com/gnome-terminal) | Requires `dconf`; clone the repo and run its installer. The page says it can work with GNOME-based terminals. | This is a terminal palette, not automatically a Ptyxis profile; Ptyxis compatibility and profile ownership remain to be verified. |
| tmux | `dracula/tmux` through TPM; [official instructions](https://draculatheme.com/tmux) | Add `set -g @plugin 'dracula/tmux'`, add TPM's `run` hook, start tmux, and run TPM install (`prefix + I`). | Themes the tmux status line and related UI, not the underlying terminal palette. |
| FZF | Official catalog port; [official instructions](https://draculatheme.com/fzf) | Set `FZF_DEFAULT_OPTS` in Zsh with Dracula foreground, background, highlight, prompt, pointer, and marker colors. | Shell environment state; safe to express in the managed `.zshrc` if the setting is owned. |
| Zsh | `dracula/zsh`, intended for Oh My Zsh; [official instructions](https://draculatheme.com/zsh) | Install the theme and its `lib` directory into the Oh My Zsh themes directory, set `ZSH_THEME="dracula"`, and reload. Zsh 5.0.8+ is recommended. | The repository uses native Zsh with a managed Powerlevel10k prompt, not Oh My Zsh; adopting this would replace an existing prompt architecture. |
| zsh-syntax-highlighting | `dracula/zsh-syntax-highlighting`; [official instructions](https://draculatheme.com/zsh-syntax-highlighting) | Requires the separate `zsh-syntax-highlighting` utility; place the Dracula style before the utility is sourced. | The utility is not currently installed by the baseline, so this is a feature addition rather than a palette-only setting. |
| Powerlevel10k | `dracula/powerlevel10k`; [official instructions](https://draculatheme.com/powerlevel10k) | Install Powerlevel10k and replace the prompt configuration with the port's files. | Existing `home/dot_p10k.zsh` is an intentionally managed custom prompt; replacing it is a deliberate ownership decision. |
| eza | Community port listed in the official catalog; [official instructions](https://draculatheme.com/eza) | Set `EZA_COLORS` in `.zshrc` to the published Dracula values. | The source repository is `urrickhunt/Dracula-for-eza`, not the Dracula organization; treat as an official-catalog community port. |
| Git | `dracula/git`; [official instructions](https://draculatheme.com/git) | Theme the terminal first, then merge the port's `config/gitconfig`; Git's own colors are limited to eight named colors. | Existing `.gitconfig` is managed; merge only the color keys and preserve functional settings. |
| ripgrep | Official catalog port; [official instructions](https://draculatheme.com/ripgrep) | Requires a ripgrep config file; add Dracula path, line, column, and match color settings. | A new `~/.config/ripgrep/config` would be a safe-machine preference candidate. |
| Spotify TUI | `dracula/spotify-tui`; [official instructions](https://draculatheme.com/spotify-tui) | Merge the `dracula.yml` theme section into `~/.config/spotify-tui/config.yml`; the terminal background must already be Dracula. | This applies to the optional Spotify TUI, not the installed Spotify desktop client. |
| Claude Code | Listed as a Team Pick in the current [official catalog](https://draculatheme.com/), but its page was not retrievable during this research. | No implementation-ready activation instructions were available. | Keep as an unresolved candidate until the port's source and Claude Code theme mechanism are verified. |

## No applicable free port found

No current official Dracula catalog page or repository suitable for the installed product was found for 1Password Stable, Spotify desktop, diagrams.net Desktop, DBeaver Community, DevToys, Flameshot, AWS CLI, GitHub CLI, mise, zoxide, bat, .NET SDK, or the native Discord Stable client.

Discord has separate catalog pages for BetterDiscord and Vesktop, but those are modified clients rather than the managed official Discord package, so they are not a native support match. Ptyxis has no dedicated catalog page; the GNOME Terminal and GTK ports are indirect candidates and must not be treated as confirmed Ptyxis support without checking its actual profile/configuration model.

## Implications for the next ticket

The next investigation should map persistence and ownership boundaries for VS Code, Chrome, Slack, Obsidian, GTK/Ptyxis, tmux/TPM, the shell environment, Git, ripgrep, and the optional Spotify TUI/Claude Code candidates. The high-risk boundaries are browser/profile state, Slack account state, Obsidian vault state, GNOME desktop settings, and replacing the existing Powerlevel10k prompt.

## Sources

- [Dracula Theme catalog](https://draculatheme.com/) — current application index; it identifies the catalog as 458+ themes and includes VS Code, Chrome, Slack, Claude Code, Zsh, GNOME Terminal, GTK, Powerlevel10k, tmux, Obsidian, FZF, Git, ripgrep, and eza.
- [Dracula Theme GitHub organization](https://github.com/dracula) — official organization and repository ownership context.
- [Dracula Theme open-source repository](https://github.com/dracula/dracula-theme) — free palette and explanation that the application ports are maintained as separate repositories.
