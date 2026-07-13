# Configure selected GNOME Shell extensions through chezmoi

## Destination

After Ubuntu bootstrap, install and enable Dash to Dock, Blur my Shell, Vitals, and Live Lock Screen through official GNOME Extensions distribution channels compatible with the host's GNOME Shell. Disable the Ubuntu AppIndicators provider and remove the user-installed third-party AppIndicator provider. Apply only safe Dracula-compatible defaults, preserve personal layout choices, and report compatibility or activation failures clearly.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `chezmoi`, `research`, `domain-modeling`, and `wayfinder` skills. The host currently runs Ubuntu 26.04 with GNOME Shell 50.1. Integrate with the existing Dracula desktop-theme setup and use the repository's public-safe, official-source convention. Vitals uses its bundled GSettings schema and requires `gir1.2-gtop-2.0` and `lm-sensors` from the Ubuntu package manifest.

The agreed ownership boundary is conservative: chezmoi owns installation, enablement, and only theme-relevant or compatibility-safe defaults; user-selected dock layout, blur preferences, panel behavior, and other personal settings remain preserved unless a ticket finds a necessary compatibility setting.

## Decisions so far

<!-- Closed tickets are appended here as the route advances. -->

- Use the official GNOME Extensions API to select the newest active release compatible with the running GNOME Shell. Install Vitals as `Vitals@CoreCoding.com`.
- Configure Vitals only with the hot sensors list and right-side panel position; preserve all other extension preferences.
- Configure Live Lock Screen with NASA's public-domain Clouds 101 animation, looping without audio, with a gentle fade and prompt blur.
- Prefer the installed FiraCode Nerd Font Mono in Ptyxis and VS Code terminals, and fail the Ptyxis hook if fontconfig cannot resolve it.

## Not yet specified

- Whether the system AppIndicators package should ever be removed; chezmoi currently disables it without requiring privileged package removal.
- Whether to offer an alternate lock-screen animation; the default is intentionally a quiet, low-altitude cloud loop.

## Out of scope

- Installing or configuring unrelated GNOME Shell extensions.
- Enforcing a complete opinionated desktop layout such as dock position, size, autohide, blur strength, or panel arrangement.
- Replacing GNOME's shell, display manager, icons, fonts, or wallpaper theme beyond the existing Dracula desktop setup.
