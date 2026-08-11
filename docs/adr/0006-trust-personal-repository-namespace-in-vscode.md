# The personal repository namespace is trusted in VS Code

VS Code trusts the personal repository namespace `~/repos/github/stefan-karlsson`. Existing trusted folders are preserved and every other namespace in the repository workspace stays restricted.

Folder trust is machine state held outside `settings.json`. Chezmoi writes the trust record atomically, only while VS Code is closed, and keeps a bounded set of backups.
