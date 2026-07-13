# Inventory and Classify Shared Behavior

Type: research
Status: resolved

## Question

Which duplicated behavior in the current chezmoi apply scripts and shell-test suite is a repository-wide policy or harness concern worth extracting, and which similar-looking code must remain local because its semantics differ?

## Answer

Extracted repository-wide shell policy into render-time fragments, shared JSON file safety into an embedded Python fragment, and test lifecycle/execution/assertion behavior into `tests/test-helpers.sh`. Domain-specific installation/configuration operations and command mocks remain local.
