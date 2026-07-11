# Dotfiles

This context defines the personal Ubuntu desktop environment represented by this chezmoi source state.

## Language

**Developer Shell**:
The managed interactive Zsh environment for developer command-line work.
_Avoid_: login shell, terminal emulator, shell script runtime

**Account shell**:
The executable recorded for a Unix user account and started for new login sessions.
_Avoid_: Developer Shell, terminal emulator, shell script runtime

**VS Code Stable**:
The Microsoft stable-release Visual Studio Code desktop editor installed from the official apt repository.
_Avoid_: VS Code Insiders, Code - OSS, Snap VS Code

**System editor**:
The machine-wide text-editor selection exposed through the Debian alternatives system, plus the bootstrap user's `text/plain` desktop MIME association.
_Avoid_: Developer Shell editor environment, VS Code user settings

**Nautilus hidden-file preference**:
The per-user GNOME Files setting that determines whether dot-prefixed files and directories are visible in Nautilus.
_Avoid_: explorer hidden-files setting, system-wide hidden-files setting
