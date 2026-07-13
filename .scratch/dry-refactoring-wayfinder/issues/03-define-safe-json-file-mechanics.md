# Define Safe JSON File Mechanics

Type: grilling
Status: resolved
Blocked by: 01

## Question

What reusable render-time fragment or embedded utility contract should cover symlink protection, permissions, bounded backups, atomic replacement, and cleanup for JSON state files while leaving Chrome, Slack, and Obsidian schema mutations independent?

## Answer

`atomic-json-state.py` provides parameterized JSON-object loading and atomic writing with symlink protection, preserved/default permissions, bounded three-file backups, fsync plus replace, and temporary-file cleanup. Chrome, Slack, Obsidian, and VS Code retain their own schema mutation logic.
