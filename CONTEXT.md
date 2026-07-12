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

**Safe machine default**:
A non-secret setting that applies to the workstation itself and does not depend on a personal account, workspace, or service identity.
_Avoid_: credential, account configuration, workspace selection, personal preference

**Node toolchain**:
The managed developer environment for multiple Node.js runtimes and JavaScript package managers used by the Developer Shell.
_Avoid_: system Node.js installation, global package state

**Node LTS default**:
The latest long-term-support Node.js runtime selected when no project-specific runtime has been requested.
_Avoid_: permanently pinned Node version, project runtime selection

**.NET SDK baseline**:
The supported .NET software-development kit provided by the Ubuntu workstation for building and running .NET projects.
_Avoid_: .NET runtime only, project-specific SDK selection
