# Confirm the .NET 10 solution-file default

Type: research
Status: resolved

## Question

Can the managed .NET CLI be configured to prefer `.slnx` over legacy `.sln` files, and does the repository's .NET 10 SDK baseline already provide that behavior?

## Answer

Yes, the .NET 10 SDK already defaults `dotnet new sln` to the `.slnx` format. No environment variable, alias, or wrapper is needed. Use `dotnet new sln --format sln` only when a legacy `.sln` file is deliberately required.
