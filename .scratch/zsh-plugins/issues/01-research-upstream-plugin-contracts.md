# Research Upstream Plugin Contracts and Pins

Type: research
Status: resolved

## Question

Which official upstream repositories, immutable tags or commits, runtime requirements, installation files, and compatibility constraints should the managed Zsh plugin set use for `zsh-autosuggestions`, `zsh-syntax-highlighting`, `you-should-use`, and `zsh-bat` on the repository's supported Ubuntu environment?

## Answer

Use the official GitHub repositories and these immutable commits:

- `zsh-autosuggestions` — `zsh-users/zsh-autosuggestions`, commit `e52ee8ca55bcc56a17c828767a3f98f22a68d4eb` (v0.7.1), source `zsh-autosuggestions.zsh`.
- `zsh-syntax-highlighting` — `zsh-users/zsh-syntax-highlighting`, commit `db085e4661f6aafd24e5acb5b2e17e4dd5dddf3e` (0.8.0), source `zsh-syntax-highlighting.zsh`; upstream requires it to be sourced last.
- `you-should-use` — `MichaelAquilina/zsh-you-should-use`, commit `ff371d6a11b653e1fa8dda4e61c896c78de26bfa` (1.11.1), source `you-should-use.plugin.zsh`; upstream supports Zsh 5.1+.
- `zsh-bat` — `fdellwing/zsh-bat`, commit `467337613c1c220c0d01d69b19d2892935f43e9f`, source `zsh-bat.plugin.zsh`; it is a no-op when `bat`/`batcat` is unavailable and otherwise aliases `cat` to the available bat command.

The metadata records the pins and source contracts, and the Ubuntu installer uses shallow clone/fetch operations so it does not download unbounded repository history.
