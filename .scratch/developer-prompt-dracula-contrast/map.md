# Make the Developer prompt readable with Dracula

## Destination

Produce an implementation-ready plan for updating the existing lean Powerlevel10k Developer prompt so every configured prompt state remains readable with the Dracula terminal palette, while preserving the current prompt layout and behavior.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `chezmoi`, `grilling`, `domain-modeling`, `prototype`, and `wayfinder` skills as relevant. The source of truth is `home/dot_p10k.zsh`; keep the change limited to prompt color/contrast configuration and its verification.

Agreed direction: preserve the current segment layout; use canonical Dracula hex colors rather than numeric terminal palette indexes; cover all enabled and conditional prompt states; require deterministic repository checks plus a manual visual check in Dracula Ptyxis. Do not redesign the prompt or alter unrelated terminal, font, icon, shell, or application theme settings.

## Decisions so far

<!-- Closed tickets are appended here as the route advances. -->

## Not yet specified

- The exact Powerlevel10k foreground/background and inline formatter settings that control each configured segment under the current lean style.
- The final Dracula color assignment for each segment and state, including whether any transparent-layout adjustments are needed to achieve readable contrast.
- The precise rendered-test assertions and manual smoke-check procedure that should make regressions diagnosable.

## Out of scope

- Redesigning the Developer prompt layout or changing its enabled segments.
- Replacing Powerlevel10k or adopting an unrelated prompt theme.
- Changing the Dracula terminal palette, Developer font, shell behavior, icons, or unrelated application colors.
- Supporting non-Dracula terminal palettes in this effort.
