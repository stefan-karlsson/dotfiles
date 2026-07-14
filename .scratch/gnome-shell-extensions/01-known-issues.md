# GNOME Shell extension compatibility research

Date: 2026-07-14
Host: GNOME Shell 50.1
Scope: the four user-installed extensions managed by chezmoi, plus the system Ubuntu Dock extension that is also loaded by GNOME Shell.

## Local inventory

| Extension | Installed version | Local state | Assessment |
| --- | ---: | --- | --- |
| Dash to Dock | 105 | ACTIVE | High-risk interaction with Ubuntu Dock |
| Blur my Shell | 72 | ACTIVE | Medium-risk interaction with Live Lock Screen and GNOME 50 startup |
| Vitals | 77 | ACTIVE | No lock-screen-related issue found |
| Live Lock Screen | 3.2.0 (8) | INACTIVE while unlocked | Expected while unlocked; activates in `unlock-dialog` mode |
| Ubuntu Dock (system) | 105 | ERROR | High-risk; duplicate dock implementation |

The enabled user-extension list contains Dash to Dock, Blur my Shell, Vitals, and Live Lock Screen. `gnome-extensions list --enabled` also reports Ubuntu Dock enabled, although it is not present in the user GSettings list. The local journal contains 5,977 lines matching the Ubuntu Dock/Dash to Dock and GNOME stage-view error patterns, including `dockManager is null`.

## Findings

### 1. Ubuntu Dock and Dash to Dock are the strongest local problem

Ubuntu Dock is a modified version of Dash to Dock, and Ubuntu’s own package description says Dash to Dock can replace it. Running both gives GNOME Shell two extensions managing the same dock and shared shell objects. The Ubuntu Dock package has a known `dockManager is null` report that was identified as a possible Dash-to-Dock/Ubuntu-Dock interaction, and the Dash to Dock issue index currently includes open GNOME 50/Wayland reports for locking freezes, invisible panels, dock crashes, and the same `dockManager is null` error:

- [Ubuntu Launchpad bug #2081602: gnome-shell dockManager is null](https://bugs.launchpad.net/bugs/2081602)
- [Ubuntu Dock package description and GNOME 50 package changelog](https://bugs.launchpad.net/ubuntu/+source/gnome-shell-extension-ubuntu-dock/102ubuntu2)
- [Dash to Dock open issues](https://github.com/micheleg/dash-to-dock/issues)

This is a direct match for the local error stream and is the most credible extension-related cause of instability during lock/unlock transitions. The chezmoi installer installs Dash to Dock but does not explicitly disable Ubuntu Dock.

### 2. Live Lock Screen has current GNOME/Ubuntu compatibility reports

The upstream project supports GNOME 46+ and the installed release is 3.2.0. Its current issue tracker has an Ubuntu 24 report where the required GStreamer sink package is unavailable and a GNOME 50.1 report where the extension disables itself after running:

- [Live Lock Screen issue #16: Not working on Ubuntu 24.0](https://github.com/nick-redwill/LiveLockScreen/issues/16)
- [Live Lock Screen issue #18: It disables itself after running](https://github.com/nick-redwill/LiveLockScreen/issues/18)
- [Live Lock Screen upstream repository](https://github.com/nick-redwill/LiveLockScreen)

No upstream issue found exactly matches “black until mouse movement”, but the extension is not yet a low-risk component on GNOME 50.1. Its lock-dialog-only activation also means its runtime state appears `INACTIVE` during a normal unlocked session.

### 3. Blur my Shell has a relevant startup regression and overlaps Live Lock Screen

Blur my Shell has an open report that blur pipelines are not applied to actors at system start/login until a state change occurs. That is similar in shape to a surface becoming correct only after pointer input or another event. Locally, Blur my Shell and Live Lock Screen both patch GNOME’s unlock-dialog background methods, so they are a real compatibility boundary even though the upstream report is not specifically about Live Lock Screen:

- [Blur my Shell issue #921: blur pipelines not applied at system start/login](https://github.com/aunetx/blur-my-shell/issues/921)
- [Blur my Shell open issues](https://github.com/aunetx/blur-my-shell/issues)

The current local configuration disables Blur my Shell’s lock-screen blur while preserving desktop blur. That is an appropriate isolation measure, but it has not been treated as a confirmed fix for the black-first-frame symptom.

### 4. Vitals does not currently look related

Vitals’ current open issues concern sensor discovery, fan readings, battery sensors after hibernation, storage, and layout. I found no current issue connecting Vitals to lock-screen rendering, pointer-triggered repainting, or GNOME Shell 50 lock transitions:

- [Vitals open issues](https://github.com/corecoding/Vitals/issues)

Vitals remains worth keeping enabled while testing because it is a shell extension, but it is a low-priority suspect for this particular problem.

## Ranked conclusion

1. Disable Ubuntu Dock and keep Dash to Dock as the only dock implementation. The local `ERROR` state and `dockManager is null` journal errors make this the first compatibility issue to eliminate.
2. If the black lock screen remains, test Live Lock Screen with all other nonessential extensions disabled. Its upstream tracker has unresolved Ubuntu and GNOME 50.1 reports.
3. Keep Blur my Shell’s lock-screen component disabled while Live Lock Screen owns the lock background; the two extensions modify the same GNOME unlock-dialog background methods.
4. Vitals is unlikely to be the cause based on both local evidence and its current issue list.

The recommended Ubuntu Dock disablement is implemented in the chezmoi GNOME extension installer. It disables the system extension when GNOME reports it `ACTIVE` or `ERROR`, while preserving the user extension list when Ubuntu Dock is not present there. The Live Lock Screen configuration separately disables Blur my Shell’s lock-screen blur and removes the video fade-in.
