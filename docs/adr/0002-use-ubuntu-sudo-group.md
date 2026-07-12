# Use Ubuntu’s standard sudo group

The existing workstation login account will use Ubuntu’s standard `sudo` group for administrative access, enforced idempotently by chezmoi when the account can authenticate an existing sudo policy. If it cannot currently use sudo, chezmoi fails with migration guidance because an unprivileged account cannot grant itself authorization. We will not create custom sudoers rules, grant `NOPASSWD`, or change root-account state, preserving password authentication and Ubuntu’s auditable default policy.
