# Define profile selection and lifecycle

Type: grilling
Status: resolved

## Question

What exact command-line and chezmoi configuration contract should select the optional `private` or `company` overlay, persist that choice locally, validate it on reruns, and require an explicit operation when switching overlays? Define behavior for omitted profiles, invalid values, conflicting local state, and direct non-bootstrap `chezmoi apply`.

## Comments

## Answer

Use `install.sh` as the profile-aware entrypoint.

- `install.sh` with no profile argument applies the default-only setup.
- `install.sh --profile default|private|company` selects the profile on first bootstrap. `--profile default` is accepted explicitly as an alias for omitting the option.
- The selected value is normalized and persisted as `[data.profile].name` in chezmoi's generated local configuration, with `default` stored for a default-only bootstrap. This configuration is machine-local and is never committed to the public source repository.
- Re-running with the same profile proceeds normally. Re-running with a different profile refuses to proceed and directs the user to an explicit switch operation, represented by `install.sh --switch-profile default|private|company`.
- A profile switch validates the target, collects and confirms all required target identity inputs, then updates local configuration and applies the source state transactionally. Cancellation or validation failure leaves the current profile and its persisted inputs unchanged. Switching never uninstalls applications or deletes prior profile configuration.
- `--profile` and `--switch-profile` are mutually exclusive. Unknown profile names, malformed local profile state, and conflicting arguments fail before rendering or installing anything.
- Direct `chezmoi apply` reads only the persisted profile and profile inputs. It accepts no temporary profile override, remains non-interactive, and fails with configuration guidance when required data for the persisted `private` or `company` profile is absent.
- Environment variables are not a second source of truth for profile selection. They may be used internally by the wrapper while invoking chezmoi, but the persisted local configuration is authoritative for subsequent applies.
