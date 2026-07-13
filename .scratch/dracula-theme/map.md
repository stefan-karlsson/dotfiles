# Configure the free Dracula theme across managed workstation applications

## Destination

Produce an implementation-ready plan for chezmoi to configure the free Dracula theme after Ubuntu bootstrap in every managed workstation application that officially supports it, including developer-shell tools. Unsupported applications remain unchanged, and failures to install or activate a supported theme are reported clearly.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `chezmoi`, `grilling`, `domain-modeling`, and `wayfinder` skills. Use the existing official-installation-channel convention and preserve user data unless a ticket explicitly decides that a managed preference owns it.

Agreed scope: the Ubuntu bootstrap baseline and its developer-shell tools, not arbitrary software installed outside the source state. Use only free Dracula themes from official Dracula-hosted distribution channels, including official marketplace or community entries; do not use Dracula Pro or unrelated ports. Skip unsupported applications, but fail clearly when a supported managed application cannot be installed or configured.

## Decisions so far

<!-- Closed tickets are appended here as the route advances. -->

- [Inventory official Dracula support for the managed baseline](./issues/01-inventory-official-dracula-support.md) — confirmed free ports and activation paths for VS Code, Chrome, Slack, Obsidian, GTK/GNOME terminal palettes, tmux, FZF, Powerlevel10k, Git, ripgrep, and eza; separated unsupported apps and profile-boundary candidates.

- [Map persistent configuration boundaries](./issues/02-map-persistent-configuration-boundaries.md) — separated source-owned settings from Chrome profile, desktop, account, workspace, and vault state; added process-safety and backup rules.
- [Decide supported-application ownership](./issues/03-decide-supported-application-ownership.md) — selected automatic ownership for VS Code, Chrome, GTK/Ptyxis, tmux, shell tools, Git, ripgrep, eza, Slack, and existing Obsidian vaults.
- [Choose theme asset update strategy](./issues/04-choose-theme-asset-update-strategy.md) — selected official Marketplace/Web Store channels and guarded fast-forward updates for Dracula Git repositories.
- [Design bootstrap and verification seams](./issues/05-design-bootstrap-and-verification-seams.md) — recorded script ordering, safe JSON mutation, failure behavior, and rendered CI coverage.

## Not yet specified

- Whether a future Dracula-supported application should be added to the managed baseline.

## Out of scope

- Dracula Pro or any paid theme variant.
- Applications installed manually or outside the managed workstation application baseline.
- Themes for applications with no free official Dracula support.
- Reworking unrelated application preferences, fonts, icons, wallpapers, or shell behavior.
