# Design owned AWS and Aspire template-pack installation

Type: grilling
Status: resolved
Blocked by: 01

## Question

What idempotent command flow should the dedicated template script use to install or update only `Amazon.Lambda.Templates` and `Aspire.ProjectTemplates`, preserve unrelated `dotnet new` template packs, and report package or source failures clearly?

## Answer

The script checks for `dotnet` and calls `dotnet new install` only for `Amazon.Lambda.Templates` and `Aspire.ProjectTemplates`. The .NET CLI updates an already-installed package to the latest stable version, so no broad `dotnet new update` is needed and unrelated template packs remain untouched.
