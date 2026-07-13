# Design latest-compatible global .NET tool installation

Type: grilling
Status: resolved
Blocked by: 01

## Question

What idempotent command flow should the dedicated global-tool script use to install or update exactly `dotnet-ef`, `Amazon.Lambda.Tools`, and `Aspire.Cli` for the user, while preserving unrelated tools, surfacing network/package failures, and keeping the user-global tool directory executable from the Developer Shell?

## Answer

The script checks for `dotnet` and `jq`, reads `dotnet tool list --global --format json`, and calls `dotnet tool update --global` for installed owned tools or `dotnet tool install --global` for missing ones. It owns only `dotnet-ef`, `Amazon.Lambda.Tools`, and `Aspire.Cli`. The Developer Shell prepends `$HOME/.dotnet/tools` to `PATH`; command failures remain fatal.
