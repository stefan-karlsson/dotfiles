# Managed Zsh Plugin Set Map

## Destination

An implementation-ready plan for installing and configuring the article's five in-scope Zsh capabilities in the chezmoi-managed Developer Shell: the curated Git shortcuts, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `you-should-use`, and `zsh-bat`, with `nvm` excluded.

The plan must also preserve the existing global Git default branch of `main`, define pinned upstream sources, and specify safe installation, loading, upgrade, and verification behavior.

## Notes

Domain: the single-context Dotfiles repository and its managed Ubuntu desktop environment.

Consult the `chezmoi`, `domain-modeling`, and `grilling` skills when working tickets. The managed Zsh plugin set is installed on Ubuntu; its interactive-shell integration remains platform-neutral and dependency-gated.

Standing decisions from charting:

- Do not adopt Oh My Zsh; use standalone upstream plugin repositories for the four external plugins.
- Reproduce the article's highlighted Git shortcuts plus `g='git'`, rather than forking the full Oh My Zsh Git plugin.
- Pin each external plugin to an immutable tag or commit and manage checkouts under `${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins`.
- Refuse to overwrite local checkout changes; invalid or unavailable pinned checkouts fail the apply-time installation step, while shell startup remains graceful when a dependency is unavailable.
- Install only on Ubuntu; load only in interactive Developer Shells; exclude `nvm` because `mise` owns the Node toolchain.
- `home/dot_gitconfig.tmpl` already configures `[init] defaultBranch = main`; preserve that existing configuration.

## Decisions so far

<!-- Closed child tickets are appended here as they resolve. -->

- [Research Upstream Plugin Contracts and Pins](issues/01-research-upstream-plugin-contracts.md) — Selected official upstream repositories, immutable commits, source files, and shallow checkout behavior for the four external plugins.

## Not yet specified

<!-- Remaining sharp questions live in the open child tickets. -->

## Out of scope

- Installing or configuring the article's `nvm` plugin.
- Adopting Oh My Zsh or copying its complete Git plugin bundle.
- Installing the plugin checkouts for macOS or other platforms before their bootstrap support is defined.
- Making plugin repositories runtime dependencies of the chezmoi source tree.
