# Managed Zsh plugin set

The Developer Shell uses four standalone upstream Zsh plugins and a curated set of Git aliases. It does not install Oh My Zsh or the article's `nvm` plugin; `mise` remains the authoritative Node toolchain manager.

The plugin checkouts and immutable commit pins live in `home/.chezmoidata/packages.toml`. The Ubuntu apply script installs them under `${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins`, refuses symbolic links and dirty checkouts, and repairs missing checkouts on every apply. A correct checkout does not require a network operation.

## Upgrade a plugin pin

1. Review the upstream release or commit and its source-file contract.
2. Update only that plugin's `commit` in `home/.chezmoidata/packages.toml`.
3. Render the installer and run its syntax, ShellCheck, and installer tests:

   ```sh
   chezmoi execute-template --file home/.chezmoiscripts/run_always_after_20-install-zsh-plugins.sh.tmpl > /tmp/install-zsh-plugins.sh
   bash -n /tmp/install-zsh-plugins.sh
   shellcheck /tmp/install-zsh-plugins.sh
   bash tests/test-install-zsh-plugins.sh /tmp/install-zsh-plugins.sh
   ```

4. Run the rendered Zsh tests and `chezmoi apply` without `--force`.
5. Confirm the checkout resolves to the declared commit and run `chezmoi verify --exclude scripts`.

Do not replace a commit pin with a moving branch name or force-overwrite a checkout containing local changes.
