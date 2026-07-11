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

Bootstrap installs a native Zsh developer shell with completion, the lean
Powerlevel10k Developer prompt, shared private history, and `fzf`, `zoxide`, `bat`,
`eza`, and `ripgrep`; it also sets Zsh as the account shell and starts the Developer
Shell when bootstrap runs.
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
It configures FiraCode Nerd Font Mono with ligatures for the editor and uses Zsh with
the same font in the integrated terminal. It does not manage extensions, keybindings,
snippets, workspace state, or VS Code's color theme. Start it from the app launcher,
`code`, or `code .`.

Bootstrap stops with migration guidance if it finds Snap VS Code, Code - OSS, or a
VS Code installation outside this managed setup; it never removes another editor
installation automatically.

## Developer terminal

Each `chezmoi apply` downloads the latest official FiraCode Nerd Font Mono release
into the user font directory, refreshes Fontconfig, and fast-forwards Powerlevel10k
from its official upstream. Ptyxis uses that font at 13pt and keeps its existing
palette. Powerlevel10k provides the same Developer prompt in Ptyxis and the VS Code
integrated terminal. Existing font and theme settings in other terminal emulators are
untouched.

## Google Chrome

Bootstrap installs Google Chrome Stable from Google's official amd64 apt repository.
Chrome is the bootstrap user's default browser for HTTP, HTTPS, HTML, and XHTML
links, and receives updates through the system package manager.

## 1Password

Bootstrap installs 1Password Stable and 1Password CLI from 1Password's official
amd64 apt repository. Chezmoi uses interactive 1Password account mode: it prompts
to unlock or sign in only when rendering a future secret-backed template. No secret,
service-account token, or 1Password item reference is stored in this repository.

After bootstrap, open 1Password and sign in, then enable system authentication in
Settings → Security and CLI integration plus the SSH agent in Settings → Developer.
Import the existing `~/.ssh/id_ed25519_github` key into 1Password, run
`chezmoi apply` again to switch GitHub SSH to the agent, then verify both
`op vault list` and `ssh -T git@github.com`. Then switch this dotfiles repository
to SSH before removing the local private key:

```sh
git -C "$(chezmoi source-path)" remote set-url origin git@github.com:stefan-karlsson/dotfiles.git
```

The bootstrap never deletes the local key automatically.

Future secret-backed templates should use a 1Password secret reference, for example
`{{ onepasswordRead "op://vault/item/field" }}`, without committing a real reference
unless it is safe to disclose. Bootstrap stops with migration guidance if it finds
Snap, Flatpak, or unmanaged-package 1Password installations.

## Daily operations

```sh
chezmoi cd
git pull --ff-only
chezmoi diff
chezmoi apply
chezmoi verify --exclude scripts
```

Use `chezmoi add`, `chezmoi edit`, and `chezmoi cat` when introducing a managed file. Do not use `--force` unless the intended overwrite has been reviewed. Refresh externals only when an external dependency is deliberately changed or refreshed.

If a pulled update changes `.chezmoi.toml.tmpl`, regenerate the local ChezMoi
configuration once before applying it:

```sh
chezmoi apply --init
```

## GitHub SSH setup

After completing the 1Password setup above, use the imported key through the
1Password SSH agent. Do not create a replacement local private key. If this is a
new machine without an existing key, generate an SSH key in 1Password, add its public
key in GitHub Settings → SSH and GPG keys, and verify it with:

```sh
ssh -T git@github.com
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
