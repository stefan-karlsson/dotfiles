# Dotfiles

This context defines the personal Ubuntu desktop environment represented by this chezmoi source state.

## Language

**Developer Shell**:
The managed interactive Zsh environment for developer command-line work.
_Avoid_: login shell, terminal emulator, shell script runtime

**Developer terminal**:
Ptyxis and the VS Code integrated terminal when used for developer command-line work.
_Avoid_: Developer Shell, an arbitrary terminal emulator, a terminal theme

**Developer prompt**:
The lean, single-line Powerlevel10k prompt in the Developer Shell, including Git status and Nerd Font icons.
_Avoid_: Developer Shell, a terminal theme, a shell script prompt

**Developer font**:
FiraCode Nerd Font Mono, used by the Developer terminals and VS Code.
_Avoid_: the unpatched Fira Code package, a system-wide font policy

**Account shell**:
The executable recorded for a Unix user account and started for new login sessions.
_Avoid_: Developer Shell, terminal emulator, shell script runtime

**Sudo-enabled account**:
The existing workstation login account with Ubuntu's standard `sudo` group membership and password-required privilege escalation.
_Avoid_: root account, passwordless sudo, service account

**VS Code Stable**:
The Microsoft stable-release Visual Studio Code desktop editor installed from the official apt repository.
_Avoid_: VS Code Insiders, Code - OSS, Snap VS Code

**System editor**:
The machine-wide text-editor selection exposed through the Debian alternatives system, plus the bootstrap user's `text/plain` desktop MIME association.
_Avoid_: Developer Shell editor environment, VS Code user settings

**System browser**:
The bootstrap user's desktop MIME associations for web links and HTML documents.
_Avoid_: browser profile, system-wide browser policy

**Screenshot capture**:
The user's interactive desktop workflow for selecting, annotating, and saving a
screen region.
_Avoid_: full-screen-only capture, the default GNOME screenshot action

**1Password account mode**:
Chezmoi secret rendering authenticated through the user's interactive 1Password desktop account and `op` CLI.
_Avoid_: 1Password Connect, 1Password service account, stored automation token

**1Password Stable**:
The official amd64 apt channel for the 1Password desktop app and 1Password CLI.
_Avoid_: 1Password beta, Snap 1Password, Flatpak 1Password, manual installation

**1Password SSH agent**:
The local SSH authentication agent provided by 1Password for SSH keys stored in the user's 1Password account.
_Avoid_: file-backed private key, system ssh-agent

**Nautilus hidden-file preference**:
The per-user GNOME Files setting that determines whether dot-prefixed files and directories are visible in Nautilus.
_Avoid_: explorer hidden-files setting, system-wide hidden-files setting

**Managed workstation application**:
Software intentionally present in the personal Ubuntu desktop environment and maintained as part of the dotfiles source state.
_Avoid_: manually installed application, account or workspace data

**Verified artifact**:
A file fetched from a managed workstation application's official URL and admitted into the environment only after the proof its vendor publishes — a checksum or a detached signature — has been checked, or, when the vendor publishes neither, only with that limitation reported.
_Avoid_: apt package, vendor installer script executed from the network, unproven download

**Committed vendor installer**:
A managed workstation application's own installation program, kept verbatim in the source state and read from there by the script that runs it, so that what executes with root privileges is the copy reviewed in this repository rather than whatever the vendor's URL serves at apply time.
_Avoid_: verified artifact, vendor installer script executed from the network, a rewritten or patched vendor script

**Pinned FortiClient branch**:
The branch of Fortinet's official apt repository that the company FortiClient EMS manages, which is the branch a company laptop installs FortiClient from.
_Avoid_: the newest FortiClient release, an exact pinned package version, a manually installed client

**Shared package**:
A managed package that more than one enrolled apt channel carries, taken from whichever build apt ranks highest because every candidate comes from a channel this source state enrolled and pinned a key for.
_Avoid_: apt pin, pinned package version, a manual apt hold

**Superseded channel**:
A repository branch this source state used to enroll, recorded so that what an earlier apply installed from it is recognized and replaced rather than read as a foreign installation.
_Avoid_: legacy apt source file, an unmanaged repository, a rollback

**Huntress EDR agent**:
The Huntress endpoint-detection-and-response agent installed on the company laptop by its committed vendor installer and registered once to the company's Huntress organization.
_Avoid_: FortiClient, a personal endpoint security tool, a second portal registration for the same laptop

**Dracula theme**:
The free Dracula color theme selected as the visual theme for a managed workstation application that officially supports it.
_Avoid_: Dracula Pro, an unrelated third-party dark theme, an application's generic dark mode

**GNOME Shell extension**:
A user-session extension that adds or changes GNOME Shell behavior and presentation, installed and enabled through GNOME's extension system.
_Avoid_: a desktop application, a system package, or an unscoped GNOME preference

**Repository workspace**:
The user-owned directory tree for local source repositories, organized as `~/repos/<provider>/<namespace>/<repo>`.
_Avoid_: dotfiles source directory, repository contents, VS Code trust store

**Trusted repository namespace**:
The personal GitHub namespace `~/repos/github/stefan-karlsson` whose descendants are trusted by VS Code for local development.
_Avoid_: the entire repository workspace, third-party repositories

**Safe machine default**:
A non-secret setting that applies to the workstation itself and does not depend on a personal account, workspace, or service identity.
_Avoid_: credential, account configuration, workspace selection, personal preference

**Bootstrap profile**:
The explicit private- or company-laptop choice that adds a profile overlay to the default profile and determines which managed workstation applications and settings, including identity-sensitive settings, are installed or rendered during bootstrap.
_Avoid_: machine auto-detection, environment, account shell

**Default profile**:
The shared managed workstation foundation that is applied on every supported laptop before any private or company profile overlay.
_Avoid_: private profile, company profile, fallback configuration

**Profile overlay**:
The optional set of managed applications and settings layered on top of the Default profile for one laptop identity.
_Avoid_: replacement profile, machine auto-detection, ad hoc exception

**Identity-sensitive setting**:
A managed value whose correctness depends on the user's personal or company identity, such as Git authorship, repository namespace, SSH/GitHub behavior, or secret references.
_Avoid_: safe machine default, credential material, arbitrary preference

**Node toolchain**:
The managed developer environment for multiple Node.js runtimes and JavaScript package managers used by the Developer Shell.
_Avoid_: system Node.js installation, global package state

**Node LTS default**:
The latest long-term-support Node.js runtime selected when no project-specific runtime has been requested.
_Avoid_: permanently pinned Node version, project runtime selection

**Managed Zsh plugin set**:
The pinned interactive-shell extensions and Git shortcuts intentionally enabled in the Developer Shell.
_Avoid_: an Oh My Zsh installation, arbitrary user shell plugins, non-interactive shell dependencies

**.NET SDK baseline**:
The supported .NET software-development kit provided by the Ubuntu workstation for building and running .NET projects.
_Avoid_: .NET runtime only, project-specific SDK selection

**Work identity**:
The company email address, company GitLab host, and company Atlassian site recorded on the company profile, used for commits inside the company repository tree and for the Atlassian CLI sign-in. Prompted once and held in the machine-local chezmoi configuration.
_Avoid_: the Git author email, a credential or API token, a literal company host in the source state

**Agent command approval**:
The standing decision about which commands an agent CLI may run unprompted on this workstation, expressed as Claude Code's permission rules and as Codex's sandbox and approval-policy pair.
_Avoid_: a per-session approval, a bypass-permissions mode, agent authentication or account state

**Routine developer command**:
A command that reads the tree, inspects Git history, or runs a toolchain's build, test, or lint entry point, and whose effect is confined to the workspace.
_Avoid_: a publishing command, a history-discarding command, a privilege escalation, a cluster or cloud command

**Atlassian CLI**:
Atlassian's own `acli`, installed on the company laptop from the vendor's official apt channel, and the only supported command line for the company Jira site.
_Avoid_: a third-party Jira CLI, the vendor's unpinned "latest" binary, the Atlassian Jira MCP connector

**Company Atlassian site**:
The company's Atlassian Cloud host, part of the Work identity, which the Atlassian CLI signs in to from the recorded value rather than one recalled per command.
_Avoid_: an on-premise Jira server, a personal Atlassian site, Jira project or board data

**Atlassian API token**:
The credential the Atlassian CLI pairs with the Company Atlassian site, supplied by the user at sign-in and held afterwards by the desktop secret service.
_Avoid_: a managed secret reference, a shell environment export, an OAuth browser session
