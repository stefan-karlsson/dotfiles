# Kubernetes workstation toolkit

## Destination

Produce an implementation-ready spec for this chezmoi repository to install and configure a focused Kubernetes workstation toolkit on Ubuntu: Docker Engine, `kubectl`, `k9s`, and Helm, with selected provider-neutral productivity additions where justified. The spec will settle official installation channels, update behavior, Developer Shell integration, safe ownership boundaries, and verification coverage.

## Notes

This is a single-context Ubuntu dotfiles repository. Consult the `wayfinder`, `chezmoi`, `research`, `grilling`, and `domain-modeling` skills. Use the repository's official-source installation convention and existing `home/.chezmoidata/packages.toml`, apply-time scripts, Zsh, Powerlevel10k, and shell-test patterns. The `felipecrs/dotfiles` repository is a design reference for idempotent Docker setup, modify templates that preserve existing JSON, generated completions, and chezmoi script seams; do not inherit its WSL or Oh My Zsh assumptions.

Agreed direction: Ubuntu workstation baseline; Docker Engine rather than Docker Desktop; latest stable releases from official channels; provider-neutral additions only; explicit context and namespace visibility without automatic context changes; no chezmoi ownership of kubeconfig, credentials, cluster contexts, Helm repository state, or cloud authentication; Docker enabled and started as a service; deterministic CI checks plus explicit non-destructive local smoke checks.

## Decisions so far

<!-- Closed tickets are appended here as the route advances. -->

## Not yet specified

- The exact official source, architecture support, checksum/signature, migration, and refresh mechanism for each required and candidate tool.
- The final provider-neutral additions and their ownership, aliases, completions, and maintenance burden. The current implementation includes `kubectx`/`kubens` and defers `stern` pending a separate binary-release installer seam.
- The precise Developer Shell and Powerlevel10k implementation for completions, aliases, context/namespace display, and graceful behavior when Kubernetes state is unavailable.
- The exact Docker group/service migration behavior and the safe handling of pre-existing Docker, Kubernetes, k9s, Helm, and shell configuration.
- The rendered CI assertions, local smoke-check commands, and documentation needed to make the setup diagnosable without a live cluster.

## Out of scope

- Docker Desktop, rootless Docker, or managing a local Kubernetes distribution such as kind, minikube, k3d, or MicroK8s.
- Cloud-provider CLIs, authentication plugins, and provider-specific Kubernetes tooling until a separate concrete workflow requires them.
- Owning or rewriting kubeconfig files, credentials, cluster contexts, namespaces, Helm repository state, or cluster resources.
- Requiring a live Kubernetes cluster, secrets, or privileged Docker access in CI.
- Supporting non-Ubuntu platforms in this effort.
