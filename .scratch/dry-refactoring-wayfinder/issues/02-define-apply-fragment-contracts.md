# Define Apply-Time Fragment Contracts

Type: grilling
Status: resolved
Blocked by: 01

## Question

What exact render-time shell fragments should be introduced under `home/.chezmoitemplates/`, what inputs and side effects does each contract permit, and how will inclusion preserve standalone rendered apply scripts and shellcheckability?

## Answer

`shell-foundation.sh` provides `fail`, required-command checks, and warning-based command skips. `gnome-settings-foundation.sh` provides GNOME-session gating and idempotent `gsettings` writes. Both are included at render time, and each rendered apply script remains standalone with no source-tree runtime dependency.
