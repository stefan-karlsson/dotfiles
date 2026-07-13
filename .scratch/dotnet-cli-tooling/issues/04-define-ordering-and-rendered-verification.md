# Define script ordering and rendered verification

Type: task
Status: resolved
Blocked by: 02, 03

## Question

Which chezmoi script names and ordering, bootstrap prerequisites, update triggers, fake command seams, and CI checks prove that the two installers render valid shell, fail when `dotnet` is missing, are idempotent, update owned artifacts, and do not alter unrelated global tools or template packs?

## Answer

The hooks are `run_onchange_after_18-install-dotnet-tools.sh.tmpl` and `run_onchange_after_18-install-dotnet-templates.sh.tmpl`, before the existing VS Code hook. CI renders both scripts, runs Bash syntax checks and ShellCheck, and executes isolated tests covering install/update branching, owned package boundaries, missing-`dotnet` failures, idempotence, and Developer Shell PATH exposure.
