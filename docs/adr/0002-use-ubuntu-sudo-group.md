# Ubuntu’s standard sudo group

The workstation login account holds administrative access through Ubuntu’s standard `sudo` group, applied idempotently by chezmoi when the account can authenticate against an existing sudo policy. An account that cannot use sudo stops the apply with migration guidance. There are no custom sudoers rules, no `NOPASSWD`, and no change to root-account state; sudo authenticates by password.
