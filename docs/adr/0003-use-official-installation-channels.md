# Official installation channels for workstation applications

Managed workstation applications come from Ubuntu packages, from a vendor's official apt channel when it publishes a stable one, and from the vendor's official signed `.deb` when it does not. Command-line tools come from their vendor's official installer where that is the supported distribution path.

A direct package is admitted on a vendor-published checksum or signature. When a vendor publishes neither, the package comes only from the official HTTPS download URL and the limitation is stated where the package is declared. Snap carries an application only when no better channel exists. Flatpak is not used.
