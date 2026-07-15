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
privileged access is required. It installs the supported Ubuntu packages, managed
desktop applications, chezmoi `2.71.0`, and Codex CLI `0.144.1`; applies the source
state; and sets Zsh as the account shell. When run from a terminal, it also starts
the Developer Shell immediately. It is safe to rerun only when the local chezmoi
source repository is clean.

## Bootstrap profiles

Every bootstrap applies the shared default profile. Select the optional laptop
overlay explicitly on the first run:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/stefan-karlsson/dotfiles/main/install.sh)" -- --profile private
```

Use `--profile company` for a company laptop, or omit the option for the
default-only setup. The selected profile and prompted Git identity are stored in
the machine-local chezmoi configuration; credentials, tokens, and private keys
are never stored in this repository. Re-running with the same profile is safe.
Switch an existing machine explicitly with `--switch-profile` after confirming
the target identity values; profile switching never uninstalls applications or
deletes the previous profile's configuration.

## Managed workstation applications

The default profile installs the shared developer foundation, including tmux,
AWS CLI v2, Claude Code, the .NET 10 SDK, Docker Engine, `kubectl`, Helm, k9s,
`kubectx`, and `kubens`. The private profile adds Spotify, Obsidian, and
Discord, plus SlayZone; the company profile adds Slack, diagrams.net Desktop,
DBeaver Community, and DevToys. Applying a profile never removes applications
installed by another profile.
Slack uses the
official Linux beta package; the other desktop packages use their official apt
repository or `.deb` source. Account sign-in, credentials, vaults, workspaces,
and personal application preferences remain manual. Applications do not start
automatically at login.

SlayZone uses the official pinned Debian package. Its package-provided desktop
entry and hicolor icons make it available in the Ubuntu application dashboard.
On the private profile, chezmoi also exposes SlayZone's bundled `slay` CLI in
`~/.local/bin` and enables Zsh completion. The CLI requires Node 24+, supplied
by mise; `slay init` remains an explicit per-project action and no SlayZone
credentials or project state are managed here.

diagrams.net Desktop is paired with the `hediet.vscode-drawio` VS Code extension.
The extension is configured for offline mode and standard diagram files; system
file associations remain unchanged. AWS CLI shell completion is enabled in Zsh,
but AWS profiles and credentials are not managed here.

Chezmoi installs and activates the free Dracula theme where the setting is safe to
own: VS Code, GTK/Ptyxis, tmux, Powerlevel10k, Git, ripgrep, FZF, eza, and Google
Chrome. Chrome's official Web Store theme is installed automatically for the browser
and selected in each existing persistent profile; close Chrome before applying so its
JSON preferences can be updated safely. Account state and Obsidian vault contents remain
preserved while existing Slack and Obsidian profiles are activated automatically; close
both applications before applying so their preferences can be updated safely. Obsidian
scans for `.obsidian` folders and configures each vault at its discovered location; it
never derives or creates a duplicate vault directory.

On Ubuntu GNOME, chezmoi also installs and enables the latest active GNOME 50-compatible
releases of Dash to Dock and Blur my Shell from the official GNOME Extensions service. For
AppIndicator support it prefers Ubuntu's packaged `ubuntu-appindicators@ubuntu.com` extension;
the separately downloaded copy is used only on Ubuntu installations without the packaged one.
Dash to Dock is configured with 32px icons and a content-sized dock; other extension
preferences remain untouched. GNOME favorites remove Firefox and pin Google Chrome, DBeaver,
Slack, SlayZone, DevToys, Obsidian, and diagrams.net Desktop. A logout/login may be
required after a fresh installation.

Live Lock Screen uses NASA's public-domain 4K Clouds 101 animation, loops it without audio,
and uses cover scaling so the 16:9 source fills the display without distortion. The source's
native approximately 30 fps playback and color-accurate pipeline remain enabled. Blur my Shell's
lock-screen blur is disabled because both extensions modify the same GNOME unlock-dialog background;
Blur my Shell remains enabled for the desktop.

## Node toolchain

`mise` is the authoritative Node toolchain manager. It provides the latest Node
LTS as the default, supports multiple project-selected runtimes through
`mise.toml`, `.nvmrc`, or `.node-version`, and does not silently install a missing
runtime while changing directories. Run `mise install` when a project declares a
runtime that is not installed.

Corepack provides pnpm and Yarn; projects can select exact package-manager
versions with the `packageManager` field in `package.json`. Claude Code is managed
as a user-level mise npm tool, so the `claude` command remains available across
Node version changes. The Ubuntu `nodejs` and `npm` packages are intentionally not
installed.

## Unreal Engine

The Linux Unreal Engine development environment includes the C++/Vulkan
toolchain and VS Code extensions. Chezmoi manages the official precompiled
Unreal Engine 5.8 Linux build under `~/.local/share/unreal-engine/5.8` and
exposes it as `unreal-editor`.

Run `install-unreal-engine` to automate sudo authentication, opening Epic's
download page when needed, applying chezmoi, and launching the editor. The
command never stores your password or Epic credentials.

Epic requires an Epic account to download the Linux ZIP. Download the 5.8 Linux
archive from [Epic's Unreal Engine for Linux page](https://www.unrealengine.com/en-US/linux),
place it in `~/Downloads`, and run `chezmoi apply`; the installer also accepts
`UNREAL_ENGINE_ARCHIVE=/path/to/archive.zip chezmoi apply` when more than one
archive is present. The archive is intentionally not stored in this repository.

Epic recommends Ubuntu 22.04, 32 GB RAM, and a high-VRAM dedicated GPU for
smooth UE5 development. This machine's Quadro P500 is below that recommendation,
so Lumen, Nanite, and other high-end rendering features may be impractical.

## .NET SDK

The .NET 10 SDK is installed from Ubuntu 26.04's native package feed. Projects
that require another SDK can install it explicitly and select it with a
`global.json` file. The C# Dev Kit VS Code extension is not installed by default.
Chezmoi also creates and trusts the user-scoped ASP.NET Core HTTPS developer
certificate for .NET Aspire. The certificate remains in the local user certificate
store; its OpenSSL trust directory and NSS database are exposed to Developer Shell
processes.

## Developer Shell

Bootstrap installs a native Zsh developer shell with completion, the lean
Powerlevel10k Developer prompt, shared private history, and `fzf`, `zoxide`, `bat`,
`eza`, `ripgrep`, and Just; it also sets Zsh as the account shell and starts the
Developer Shell when bootstrap runs.

Kubernetes tooling is installed from the official Docker, Kubernetes, Helm, Ubuntu,
and k9s release channels. Docker Engine is enabled as a system service and the
login account is added to the `docker` group; sign out and back in after a fresh
installation before using Docker without `sudo`. The shell provides `k` for
`kubectl`, `kx` for `kubectx`, `kn` for `kubens`, and native kubectl/Helm completion.
The Powerlevel10k prompt shows the locally selected Kubernetes context and namespace
when available. Kubeconfig files, credentials, contexts, namespaces, Helm
repositories, and cloud authentication remain user-owned and unmanaged.
Just is installed from Ubuntu's package foundation and provides native Zsh
completion for project command runners.
APT-managed tools receive normal repository updates. Release artifacts use
reviewable version and checksum pins in `home/.chezmoidata/packages.toml`; refresh
those pins when a new upstream stable release is adopted. The Kubernetes apt source
tracks the current stable minor channel (`v1.36`) because Kubernetes publishes
versioned package repositories and clients should remain within one minor version of
their clusters. `stern` is intentionally deferred: k9s covers interactive log
inspection, and adding stern would require a separate binary-release installer seam.
Open Zsh manually with:

```sh
zsh
```

The shell keeps `ls`, `cat`, and `grep` unchanged. Use `l`, `la`, and `ll` for
eza directory listings; use `bat` for syntax-highlighted file output and `z <query>`
for frecency-based directory changes. The configured FZF, eza, ripgrep, Git, and
Powerlevel10k colors use the free Dracula palette. `fzf` provides its standard interactive
bindings, including Ctrl-R history search. Prefix a command with a space to omit it
from the shared history file.

## Visual Studio Code

Bootstrap installs VS Code Stable from Microsoft's apt repository and configures it
as the System editor for terminal editor commands and the bootstrap user's `text/plain`
desktop files.
It configures FiraCode Nerd Font Mono with ligatures for the editor and uses Zsh with
the same font in the integrated terminal. Chezmoi installs the `Dracula Official`
extension and selects its `Dracula` color theme. Keybindings, snippets, and workspace
state remain unmanaged. Start it from the app launcher,
`code`, or `code .`.

Bootstrap stops with migration guidance if it finds Snap VS Code, Code - OSS, or a
VS Code installation outside this managed setup; it never removes another editor
installation automatically.

## Repository workspace

Chezmoi creates the user-owned repository workspace at
`~/repos/github/stefan-karlsson`. Use the extensible layout
`~/repos/<provider>/<namespace>/<repo>` for future repositories; cloning and repository
contents remain manual. VS Code trusts only the personal GitHub namespace, while
existing trusted folders are preserved. Close VS Code before running `chezmoi apply`
so the trust configuration can be updated safely.

## Developer terminal

Each `chezmoi apply` downloads the latest official FiraCode Nerd Font Mono release
into the user font directory, refreshes Fontconfig, and fast-forwards Powerlevel10k
from its official upstream. The free Dracula GTK theme is installed from its official
repository, GNOME is switched to the Dracula GTK theme, and the official Dracula
wallpaper is selected when an upstream image is available. The default Ptyxis profile
uses the `dracula` palette. The official Dracula tmux theme is installed and sourced
from the managed tmux configuration. Existing font and theme settings in other terminal
emulators are untouched.

## Google Chrome

Bootstrap installs Google Chrome Stable from Google's official amd64 apt repository.
Chrome is the bootstrap user's default browser for HTTP, HTTPS, HTML, and XHTML
links, and receives updates through the system package manager.
Chezmoi configures the official free Dracula Chrome Web Store theme automatically for
existing persistent profiles. It preserves the rest of each browser profile and keeps
up to three timestamped backups of a changed `Preferences` file.

## Screenshot capture

Bootstrap installs Flameshot from Ubuntu's package repository and starts its
background process at login. On GNOME, `Print Screen` opens Flameshot's interactive
capture workflow; the other screenshot shortcuts remain unchanged. The integration
supports the managed Ubuntu Wayland session and remains compatible with X11.

Captures use PNG files with timestamped names under `~/Pictures/Screenshots`.
Desktop save notifications remain enabled, while clipboard copying and external
uploads are explicit actions. Chezmoi creates the capture directory and manages
the selected Flameshot preferences; it does not install a GNOME tray extension.

## 1Password

Bootstrap installs 1Password Stable and 1Password CLI from 1Password's official
amd64 apt repository. Chezmoi uses interactive 1Password account mode: it prompts
to unlock or sign in only when rendering a future secret-backed template. No secret,
service-account token, or 1Password item reference is stored in this repository.

After bootstrap, open 1Password and sign in, then enable system authentication in
Settings → Security and CLI integration plus the SSH agent in Settings → Developer.
Run `verify-1password-setup` to approve and verify CLI access and the local SSH-agent
socket. Import the existing `~/.ssh/id_ed25519` key into a 1Password **SSH Key**
item titled `GitHub CLI`, run `chezmoi apply` again to switch GitHub SSH to the
agent, then run
`verify-1password-setup --github` to verify GitHub authentication. Then switch this
dotfiles repository to SSH before removing the local private key:

```sh
git -C "$(chezmoi source-path)" remote set-url origin git@github.com:stefan-karlsson/dotfiles.git
```

The bootstrap never deletes the local key automatically.

## GitHub CLI

Bootstrap installs GitHub CLI from GitHub's official signed apt repository and
sets its public defaults to use SSH for Git operations. It also manages GitHub's
published Ed25519 host key in `~/.ssh/known_hosts`, so future bootstraps trust only
the pinned public host key. Authenticate interactively after the 1Password SSH
agent is ready:

```sh
gh auth login --web --git-protocol ssh --skip-ssh-key
gh auth status
```

Authentication tokens remain in GitHub CLI's credential store and are never managed
by chezmoi. The managed CLI config is limited to public preferences in
`~/.config/gh/config.yml`.

Future secret-backed templates should use a 1Password secret reference, for example
`{{ onepasswordRead "op://vault/item/field" }}`, without committing a real reference
unless it is safe to disclose. Bootstrap stops with migration guidance if it finds
Snap, Flatpak, or unmanaged-package 1Password installations. An existing installation
from the expected official stable apt repository is adopted without replacement.

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
