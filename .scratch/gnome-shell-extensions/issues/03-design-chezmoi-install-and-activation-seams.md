# Design chezmoi installation and activation seams

Type: grilling
Status: open
Blocked by: 01, 02

## Question

What source-state files, script ordering, dependency checks, update markers, GNOME session/process-safety behavior, and failure messages are needed to install, enable, and configure the three extensions idempotently after bootstrap without making a running Shell session or user settings unsafe?
