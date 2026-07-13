# Manage .NET CLI tools and project templates

## Destination

Add two idempotent chezmoi scripts that install the latest stable user-global .NET CLI tools for Entity Framework Core, AWS Lambda, and .NET Aspire, plus the AWS Lambda and .NET Aspire template packs. The scripts must fail clearly when the managed .NET SDK is unavailable and leave unrelated global tools and template packs untouched.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `chezmoi`, `research`, `domain-modeling`, and `wayfinder` skills. The repository owns the Ubuntu 26.04 `.NET SDK baseline` (`dotnet-sdk-10.0`), so these scripts are workstation-level configuration rather than project-local tool manifests. Use official NuGet/Microsoft/AWS sources and preserve the existing `run_onchange` installation pattern.

The agreed scope is latest stable compatible releases, user-global tools, and explicit ownership of only `Amazon.Lambda.Templates` and `Aspire.ProjectTemplates`. Missing `dotnet` is an error, not a warning or a silent skip.

The managed .NET 10 SDK already makes `dotnet new sln` generate `.slnx` by default; no unsupported CLI override is required.

## Decisions so far

<!-- Closed tickets are appended here as the route advances. -->

- [Confirm official .NET tool and template-pack contracts](issues/01-confirm-official-tool-and-template-pack-contracts.md) — Official package IDs and latest-stable install/update commands are confirmed for the .NET 10 baseline.
- [Design latest-compatible global .NET tool installation](issues/02-design-global-dotnet-tool-installation.md) — The installer owns only three global tools and uses JSON discovery to choose install versus update.
- [Design owned AWS and Aspire template-pack installation](issues/03-design-owned-template-pack-installation.md) — The template installer owns only the two requested packs and relies on `dotnet new install` latest-stable update semantics.
- [Define script ordering and rendered verification](issues/04-define-ordering-and-rendered-verification.md) — Both scripts run as separate `run_onchange_after_18` hooks with rendered syntax, behavior, failure, and PATH tests.
- [Confirm the .NET 10 solution-file default](issues/05-confirm-slnx-default.md) — `.slnx` is already the default; callers can explicitly request legacy `.sln` only when required.

## Not yet specified

None; the implementation route is clear.

## Out of scope

- Project-local `.config/dotnet-tools.json` manifests.
- Installing unrelated global tools, template packs, workloads, or SDK versions.
- AWS SAM CLI, AWS CDK, or IDE-specific extensions not required by the requested .NET Lambda tooling.
