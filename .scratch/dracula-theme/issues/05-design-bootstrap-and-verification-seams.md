# Design bootstrap ordering and verification seams

Type: grilling
Status: resolved
Blocked by: 03, 04

## Question

What chezmoi source files, apply-time script ordering, dependency checks, process-safety behavior, and rendered test coverage are required to install and activate the selected Dracula themes reliably after package bootstrap while preserving the repository's Ubuntu-only and public-safe constraints?

## Answer

Ubuntu-only `run_always_after_23` installs GTK, tmux, and wallpaper assets after package
bootstrap; `run_always_after_24` registers and activates the Chrome theme; and
`run_always_after_25`/`26` activate existing Slack and discovered Obsidian profiles.
The VS Code extension script remains `run_onchange`, while source-managed settings are
applied normally. Scripts check required commands, refuse unsafe process states, use
atomic JSON updates, preserve unrelated settings, and report failures. Rendered shell
tests cover the Dracula installer and application profile behavior, including backup
retention; CI runs syntax, ShellCheck, and focused tests. Unsupported apps remain
unchanged.
