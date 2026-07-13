# Confirm official .NET tool and template-pack contracts

Type: research
Status: resolved

## Question

For the .NET 10 SDK baseline, confirm the official package IDs, stable installation/update commands, compatibility expectations, and failure modes for `dotnet-ef`, `Amazon.Lambda.Tools`, `Aspire.Cli`, `Amazon.Lambda.Templates`, and `Aspire.ProjectTemplates`. Record which facts the installer can safely rely on without pinning versions.

## Answer

Use `dotnet-ef`, `Amazon.Lambda.Tools`, and `Aspire.Cli` as global tool package IDs. Use `Amazon.Lambda.Templates` and `Aspire.ProjectTemplates` as template package IDs. The .NET CLI defaults to the latest stable package when no version is specified; `dotnet tool update --global` updates an installed tool and `dotnet new install <package>` updates an installed template package.
