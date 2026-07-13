# Configure selected GNOME Shell extensions through chezmoi

## Destination

After Ubuntu bootstrap, install and enable Dash to Dock, Blur my Shell, and AppIndicator Support through official GNOME Extensions distribution channels compatible with the host's GNOME Shell. Apply only safe Dracula-compatible defaults, preserve personal layout choices, and report compatibility or activation failures clearly.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `chezmoi`, `research`, `domain-modeling`, and `wayfinder` skills. The host currently runs Ubuntu 26.04 with GNOME Shell 50.1 and has no installed GNOME Shell extensions. Integrate with the existing Dracula desktop-theme setup and use the repository's public-safe, official-source convention.

The agreed ownership boundary is conservative: chezmoi owns installation, enablement, and only theme-relevant or compatibility-safe defaults; user-selected dock layout, blur preferences, panel behavior, and other personal settings remain preserved unless a ticket finds a necessary compatibility setting.

## Decisions so far

<!-- Closed tickets are appended here as the route advances. -->

## Not yet specified

- The exact GNOME Extensions download/API path and compatible release selection for GNOME Shell 50.
- The persistent settings schemas and the smallest Dracula-compatible defaults for each extension.
- Bootstrap ordering, update detection, process/session safety, and rendered verification seams.

## Out of scope

- Installing or configuring unrelated GNOME Shell extensions.
- Enforcing a complete opinionated desktop layout such as dock position, size, autohide, blur strength, or panel arrangement.
- Replacing GNOME's shell, display manager, icons, fonts, or wallpaper theme beyond the existing Dracula desktop setup.
