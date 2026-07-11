# Use 1Password SSH agent for GitHub authentication

GitHub SSH authentication on managed workstations will use the 1Password SSH agent instead of a private key persisted under `~/.ssh`. During migration, the managed SSH configuration retains the local key only until the 1Password agent socket is available; the user then verifies GitHub access before removing that key. This keeps private key material in 1Password while accepting that Git SSH operations require the user's desktop account to be available and unlocked.
