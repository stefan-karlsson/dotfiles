# Trust the personal repository namespace in VS Code

VS Code will trust only the personal repository namespace `~/repos/github/stefan-karlsson`, preserving existing trusted folders and leaving other repository workspace namespaces restricted by default. Because folder trust is security-sensitive machine state stored outside `settings.json`, chezmoi will update the internal trust record atomically only when VS Code is closed and retain a bounded set of backups.
