# Ubuntu's .NET SDK baseline

The .NET LTS SDK, `dotnet-sdk-10.0`, comes from Ubuntu 26.04's native package feed. No separate Microsoft package repository is enrolled for it.

Ubuntu's feed carries the supported baseline, not the latest feature band. Chezmoi also installs the current .NET 10 SDK feature band into the user-scoped `~/.dotnet` directory with the official installer. A project that needs another SDK version selects it with `global.json` and adds that SDK itself.
