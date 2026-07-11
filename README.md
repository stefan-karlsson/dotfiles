# Stefan's dotfiles

Ubuntu 26.04 desktop foundation managed with [chezmoi](https://www.chezmoi.io/).

## Bootstrap a new Ubuntu 26.04 machine

Either `curl` or `wget` is the only initial prerequisite. Run one of:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stefan-karlsson/dotfiles/main/install.sh)"
```

```sh
sh -c "$(wget -qO- https://raw.githubusercontent.com/stefan-karlsson/dotfiles/main/install.sh)"
```

The bootstrap prints each task as it runs and may request your sudo password when
privileged access is required. It installs the supported Ubuntu packages, chezmoi
`2.71.0`, and Codex CLI `0.144.1`; applies the source state; and sets Zsh as the
account shell. When run from a terminal, it also starts the Developer Shell
immediately. It is safe to rerun only when the local chezmoi source repository is
clean.

## Developer Shell

Bootstrap installs a native Zsh developer shell with completion, a Git-aware prompt,
shared private history, and `fzf`, `zoxide`, `bat`, `eza`, and `ripgrep`; it also
sets Zsh as the account shell and starts the Developer Shell when bootstrap runs.
Open Zsh manually with:

```sh
zsh
```

The shell keeps `ls`, `cat`, and `grep` unchanged. Use `l`, `la`, and `ll` for
eza directory listings; use `bat` for syntax-highlighted file output and `z <query>`
for frecency-based directory changes. `fzf` provides its standard interactive
bindings, including Ctrl-R history search. Prefix a command with a space to omit it
from the shared history file.

## Visual Studio Code

Bootstrap installs VS Code Stable from Microsoft's apt repository and configures it
as the System editor for terminal editor commands and the bootstrap user's `text/plain`
desktop files.
It does not manage VS Code settings, extensions, keybindings, snippets, or workspace
state. Start it from the app launcher, `code`, or `code .`.

Bootstrap stops with migration guidance if it finds Snap VS Code, Code - OSS, or a
VS Code installation outside this managed setup; it never removes another editor
installation automatically.

## Daily operations

```sh
chezmoi cd
git pull --ff-only
chezmoi diff
chezmoi apply
chezmoi verify --exclude scripts
```

Use `chezmoi add`, `chezmoi edit`, and `chezmoi cat` when introducing a managed file. Do not use `--force` unless the intended overwrite has been reviewed. Refresh externals only when an external dependency is deliberately changed or refreshed.

## GitHub SSH setup

After bootstrap, create a unique passphrase-protected key for this machine:

```sh
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_github -C "stefan-karlsson@$(hostname)-github"
ssh-add ~/.ssh/id_ed25519_github
cat ~/.ssh/id_ed25519_github.pub
```

Add the displayed public key in GitHub Settings → SSH and GPG keys, verify it with `ssh -T git@github.com`, then run:

```sh
git -C "$(chezmoi source-path)" remote set-url origin git@github.com:stefan-karlsson/dotfiles.git
```

Never commit private keys, API tokens, passwords, or general `~/.codex` state. The repository is public.

## Shared agent skills

Shared agent skills live canonically in `~/.agents/skills`. Chezmoi installs them globally through the upstream `npx skills` CLI, which creates agent symlinks by default; Codex consumes those links from `~/.codex/skills`. Its system and plugin skills remain unmanaged. This layout is intentionally ready for a future Claude CLI adapter without duplicating skill content.

The selected Matt Pocock engineering skills are declared in `home/.chezmoidata/matt-pocock-skills.toml`. Update them with `update-matt-pocock-skills`; the command intentionally uses the latest upstream skill content and disables installer telemetry. Run `chezmoi verify` afterwards.

## Repository layout

- `home/` is the chezmoi source state.
- `home/.chezmoidata/` declares packages and tool versions.
- `home/.chezmoiscripts/` also bootstraps the shared global agent skills.
- `home/executable_dot_local/bin/` contains maintenance commands such as `update-matt-pocock-skills`.
- `home/.chezmoiscripts/` contains idempotent installation actions.
- `.agents/skills/chezmoi/` is the repository-local Codex workflow for maintaining this source state.

The package data already reserves Darwin formula and cask lists. macOS bootstrap and package installation will be added in a separate milestone.
