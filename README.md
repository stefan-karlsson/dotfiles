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
are never stored in this repository. The company profile also prompts once for
the Huntress account key and stores it the same way. Re-running with the same
profile is safe.
Switch an existing machine explicitly with `--switch-profile` after confirming
the target identity values; profile switching never uninstalls applications or
deletes the previous profile's configuration.

## Managed workstation applications

The default profile installs the shared developer foundation, including tmux,
AWS CLI v2, Claude Code, the .NET 10 SDK, Docker Engine, Bruno, `kubectl`, Helm, k9s,
`kubectx`, `kubens`, the Grafana CLI (`gcx`), MongoDB Compass, DevToys with its
CLI, and NoSQL Workbench for DynamoDB. The private profile adds Spotify, Obsidian, and
Discord, plus SlayZone; the company profile adds Slack, diagrams.net Desktop,
DBeaver Community, Rider, FortiClient, the GitLab CLI, the Atlassian CLI, the
Microsoft Intune Portal with Microsoft Edge, and the Huntress EDR agent. Rider is installed from
JetBrains' official stable Snap channel; FortiClient uses Fortinet's official
signed apt repository. Applying a profile never removes applications installed
by another profile.

FortiClient is pinned to the branch the company FortiClient EMS manages, currently
7.2. An EMS registers an endpoint on its own branch and turns a newer one away with
`FCT version is not supported`. An apply that finds a superseded branch's package
purges it before installing the pinned branch's version; register to the company EMS
again afterwards. The pin moves when the company EMS moves.

The Intune Portal comes from Microsoft's package channel for this Ubuntu release,
enrolled the way Microsoft's own Intune installer enrolls it; no vendor installer
script runs. Microsoft signs the 26.04 channel with a different key than the VS Code
and Edge channels, and both keys are pinned. Edge accompanies the portal and carries
compliance sign-in; Chrome remains the system browser. Open **Microsoft Intune** and
sign in after bootstrap to register the device.

Edge is enrolled as its own postinstall script enrolls it — the `repos/edge-stable`
channel and the separate `microsoft-edge.gpg` keyring holding the same pinned
Microsoft key. That script rewrites the source file on every Edge upgrade.

Microsoft's Ubuntu channel also carries `kubectl` alongside the Kubernetes channel.
A company laptop gets Microsoft's build of the current release and every other
laptop gets the Kubernetes project's build. Both channels are enrolled and
key-pinned here and both track the same upstream release, and `kubectl` is declared
as a shared package rather than held to one channel by an apt preference.

Slack uses the official Linux beta package; the other desktop packages use their
official apt repository or `.deb` source. Account sign-in, credentials, vaults, workspaces,
and personal application preferences remain manual. Applications do not start
automatically at login.

The Huntress EDR agent is installed on the company profile from the vendor
installer this repository ships verbatim at
`home/.chezmoitemplates/vendor/huntress-linux-install.sh`; the code that runs as
root is the copy held here. The installer downloads the agent package itself from
the Huntress portal, authenticated by the prompted account key, and registers the
laptop with the prompted organization. Both values are recorded in the
machine-local chezmoi configuration. An existing installation is left alone;
uninstall the `huntress-agent` and `huntress-updater` services before reinstalling
against a different account key. Updating the committed installer makes a later
apply run it again.

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

The Grafana CLI is installed as `gcx` in `/usr/local/bin` from the pinned release
archive Grafana publishes on GitHub, admitted on the checksum from that release's
own checksums file. Its Zsh completion is enabled; Grafana instances, API tokens,
and whichever stack `gcx login` is pointed at stay user-owned and unmanaged. A `gcx`
installed some other way is never overwritten — migrate it before applying.

On the company profile, Jira is worked from Atlassian's own `acli`, installed from
the vendor's official apt channel with its release-signing key pinned; it takes
ordinary apt updates and carries no version pin. The channel is enrolled as
Atlassian's Linux install guide enrolls it, down to the `acli.list` source file and
the keyring path, and an installation that followed that guide by hand is adopted.
Zsh completion is enabled.

Signing in is a one-time step and needs an API token this repository does not hold.
`chezmoi apply` records the company Atlassian site and the work email and installs
`jira-login`, which carries both:

```sh
jira-login < token.txt      # or: jira-login --web
```

Generate the token at <https://id.atlassian.com/manage-profile/security/api-tokens>.
The token is read from standard input, which keeps it out of the shell history and
the process table; `acli` hands it to the desktop secret service and nothing about
it reaches the source state. The account it signs in as is the work email described
under [Work identity](#work-identity), one value shared with the company Git
identity. Jira projects, boards, and work-item data stay user-owned and unmanaged.

Chezmoi installs and activates the free Dracula theme where the setting is safe to
own: VS Code, GTK/Ptyxis, tmux, Powerlevel10k, Git, ripgrep, FZF, eza, and Google
Chrome. Chrome's official Web Store theme is installed for the browser and selected
in each existing persistent profile; close Chrome before applying. Account state and
Obsidian vault contents are preserved while existing Slack and Obsidian profiles are
activated; close both applications before applying. Obsidian scans for `.obsidian`
folders and configures each vault at its discovered location, and never creates a
duplicate vault directory.

On Ubuntu GNOME, chezmoi also installs and enables the latest active GNOME 50-compatible
releases of Dash to Dock and Blur my Shell from the official GNOME Extensions service. For
AppIndicator support it prefers Ubuntu's packaged `ubuntu-appindicators@ubuntu.com` extension;
the separately downloaded copy is used only on Ubuntu installations without the packaged one.
Dash to Dock is configured with 32px icons and a content-sized dock; other extension
preferences remain untouched. GNOME favorites remove Firefox and pin Google Chrome, Bruno,
DBeaver, Slack, SlayZone, DevToys, Obsidian, and diagrams.net Desktop. A logout/login may be
required after a fresh installation.

Live Lock Screen uses NASA's public-domain 4K Clouds 101 animation, loops it without audio,
and uses cover scaling, which fills the display with the 16:9 source without distortion. The
source's native approximately 30 fps playback and color-accurate pipeline remain enabled. Blur my
Shell's lock-screen blur is disabled; both extensions modify the same GNOME unlock-dialog
background. Blur my Shell remains enabled for the desktop.

When connected to AC power, GNOME is configured not to suspend on inactivity or lid close, while
battery suspend behavior remains unchanged. Automatic screensaver logout is disabled.

## Node toolchain

`mise` is the authoritative Node toolchain manager. It provides the latest Node
LTS as the default, supports multiple project-selected runtimes through
`mise.toml`, `.nvmrc`, or `.node-version`, and does not silently install a missing
runtime while changing directories. Run `mise install` when a project declares a
runtime that is not installed.

Corepack provides pnpm and Yarn, each at its latest major rather than the version
bundled with the Node release; a project selects an exact package-manager version
with the `packageManager` field in `package.json`. npm comes with Node itself.
Claude Code is a user-level mise npm tool, and the `claude` command stays available
across Node version changes. The Ubuntu `nodejs` and `npm` packages are not
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

The .NET 10 SDK baseline is installed from Ubuntu 26.04's native package feed,
and the current SDK feature band (10.0.301) is installed into `~/.dotnet` for
projects that require the latest .NET 10 tooling. Projects that require another
SDK can install it explicitly and select it with a `global.json` file. The Aspire
and C# Dev Kit VS Code extensions are installed by default. Chezmoi also creates
and trusts the user-scoped ASP.NET Core HTTPS developer
certificate for .NET Aspire. The certificate remains in the local user certificate
store; its OpenSSL trust directory and NSS database are exposed to Developer Shell
processes.

## Developer Shell

Bootstrap installs a native Zsh developer shell with completion, the lean
Powerlevel10k Developer prompt, shared private history, and `fzf`, `zoxide`, `bat`,
`eza`, `ripgrep`, and Just; it also sets Zsh as the account shell and starts the
Developer Shell when bootstrap runs.

Dots walk up the file tree: `..` goes up one level, `...` two, and so on to
`......` for five. These are aliases and apply only as the first word of a command
line; `../..` inside a path argument keeps its ordinary meaning. An alias you have
already defined yourself is never replaced.

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
those pins when a new upstream stable release is adopted. Two artifacts are proven
against something other than a checksum file: MongoDB Compass carries a detached
signature, verified against MongoDB's own Compass signing key on its pinned
fingerprint, and NoSQL Workbench is read from the release manifest AWS publishes
beside the rolling download, which carries its current version and checksum and
needs no pin. The Kubernetes apt source tracks the current stable minor channel
(`v1.36`); Kubernetes publishes versioned package repositories and a client stays
within one minor version of its clusters. `stern` is not installed; k9s covers
interactive log inspection.
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
emulators are untouched. Tmux mouse selections copy directly to the desktop clipboard;
inside vi copy mode, press `v` to select and `y` or `Enter` to copy. The `wl-clipboard`
package provides this integration on Ubuntu Wayland.

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
published Ed25519 host key in `~/.ssh/known_hosts`; a bootstrap trusts only that
pinned public host key. Authenticate interactively after the 1Password SSH
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

## Work identity

The company profile commits under a work address inside `~/repos/gitlab/` while
`[user]` keeps the personal one, through an `includeIf` that git applies below
`[user]` so the later value wins. It also authenticates to the company GitLab
host through `glab`. One address serves both those commits and the Atlassian CLI
sign-in.

The work address, the GitLab host, and the Atlassian site are prompted for once on
the company profile and recorded in the machine-local chezmoi configuration, the
same way the Huntress account key is; the templates read them from there. No other
profile is asked for them, and no other profile renders the credential helper, the
`includeIf`, or `~/.gitconfig-work`. The work file renders empty off the company
profile, and chezmoi removes a target whose template renders empty.

After pulling a change that adds a prompt, run `chezmoi init` to be asked for the
new values; existing answers are kept.

## Agent command approvals

Both agent CLIs run routine developer work unprompted and stop for a person on
anything that publishes, discards, or escalates.

Claude Code matches commands against permission rules, and `~/.claude/settings.json`
enrols them by name: reading and searching the tree, Git inspection plus `add` and
`commit`, and the build, test, and lint entry points of the toolchains this
workstation carries. `git push`, `git reset`, `git checkout`, `git clean`,
`git rebase`, `rm`, `npx`, `curl`, and `kubectl` are absent from the allowlist and
keep prompting. A deny list refuses `sudo`, `su`, the host power commands,
`snowsql`, and reads of `~/.ssh`, the AWS credentials file, and Claude's own
credential file. The absolute deny paths render from `.chezmoi.homeDir` and follow
the account applying them.

Codex matches no commands against rules. `~/.codex/config.toml` states a sandbox and
approval pair: `sandbox_mode = "workspace-write"` confines a command to the
workspace and `$TMPDIR`, `approval_policy = "on-request"` carries no per-command
question, and `network_access = true` gives package installs and `git fetch` the
network from inside that sandbox. Escalation out of the sandbox is an approval.
`on-failure` is a deprecated alias for the same policy in 0.144.x.

Chezmoi owns `~/.claude/settings.json` as a whole file, and the next apply reverts a
preference changed through Claude Code's own `/config`; the theme and TUI settings
live in the source file, and further preferences belong there too. Codex
authentication, Claude Code authentication, and the rest of `~/.codex` and
`~/.claude` are unmanaged account state.

## Verifying a change

Two entry points check the source state, and CI runs exactly these:

```sh
tests/lint-sources.sh   # render every program under every profile, then lint it
tests/run-tests.sh      # run every tests/test-*.sh
```

Neither takes arguments. Both discover their work from the source tree, so a new
script under `home/.chezmoiscripts/`, a new command under `home/dot_local/bin/`,
or a new `tests/test-*.sh` is covered as soon as it is committed.

A test names its own inputs through `tests/fixture.sh`, which renders a source
template under a named Bootstrap profile and runs it against stubbed commands:

```sh
script="$(test_render_template 'home/.chezmoiscripts/run_always_after_28-configure-vitals.sh.tmpl' company)"
```

Run a single test directly while working on it — `tests/test-configure-vitals.sh`.

## Repository layout

- `home/` is the chezmoi source state.
- `home/.chezmoidata/` declares packages and tool versions.
- `home/.chezmoiscripts/` also bootstraps the shared global agent skills.
- `home/executable_dot_local/bin/` contains maintenance commands such as `update-matt-pocock-skills`.
- `home/.chezmoiscripts/` contains idempotent installation actions.
- `home/.chezmoitemplates/vendor/` holds third-party installers shipped verbatim, read raw by the script that runs them.
- `home/dot_claude/` and `home/dot_codex/` hold the agent command approvals, one file each.
- `.agents/skills/chezmoi/` is the repository-local Codex workflow for maintaining this source state.

The package data already reserves Darwin formula and cask lists. macOS bootstrap and package installation will be added in a separate milestone.
