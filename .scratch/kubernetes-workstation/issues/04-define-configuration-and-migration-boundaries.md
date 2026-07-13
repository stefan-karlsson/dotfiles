# Define configuration and migration boundaries

Type: grilling
Status: open

## Question

Which files and machine state should chezmoi own, preserve through modify templates, or leave unmanaged for Docker daemon/client configuration, the Docker service and group, `kubectl`/kubeconfig, k9s, Helm, candidate additions, and shell completion caches? Define conflict detection, existing-install adoption, re-login/restart guidance, and the safe behavior for secrets or environment-specific state.
