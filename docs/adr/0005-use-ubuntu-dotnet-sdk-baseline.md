# Use Ubuntu's .NET SDK baseline

The workstation will install the current .NET LTS SDK, `dotnet-sdk-10.0`, from Ubuntu 26.04's native package feed rather than adding a separate Microsoft package repository. Projects that require another SDK version will select it with `global.json` and can add that SDK explicitly when needed, keeping the machine baseline current without overriding project-specific compatibility.
