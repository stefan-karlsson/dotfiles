# FortiClient is pinned to the branch the company EMS supports

FortiClient comes from the 7.2 branch of Fortinet's official apt repository, which is the branch the company FortiClient EMS manages. An EMS registers an endpoint on its own branch and turns away a client from a newer branch with `FCT version is not supported`, leaving the laptop unregistered and without the VPN and compliance configuration the EMS pushes. The pin moves when the company EMS moves.

A branch pin is a version ceiling, and apt neither downgrades nor removes a package on its own. The repository data names the superseded branches. A laptop enrolled on one is recognized as this setup's own, is moved onto the pinned branch, and has the superseded branch's package purged before the pinned branch's version is installed, which is the sequence Fortinet documents for changing branch.
