# About the Project

`SPO-anywhere` is a collection of [NixOS modules](https://zero-to-nix.com/concepts/nixos#modules), [Nix](https://nixos.org) packages and Nix library functions simplifying the deployment and operation of [Cardano stake pools](https://cardano.org/stake-pool-operation/).

### Why?

[Nix](https://zero-to-nix.com/concepts/nix) is a [declarative](https://zero-to-nix.com/concepts/declarative) package manager ensuring hash-based [dependency pinning](https://zero-to-nix.com/concepts/pinning) and [reproducible](https://zero-to-nix.com/concepts/reproducibility) builds. [NixOS](https://zero-to-nix.com/concepts/nixos) is a Linux distribution with a [declarative configuration](https://zero-to-nix.com/concepts/nixos#configuration) system providing [atomic](https://zero-to-nix.com/concepts/nixos#atomicity) updates and [rollbacks](https://zero-to-nix.com/concepts/nixos#rollbacks). These features are responsible for the increased reliability of a NixOS system, making it an attractive DevOps toolset for deploying Cardano services.

### What?

By its nature, stake pool operation is a multistep process. `SPO-anywhere` guides you through this process providing a `Nix` helper functions, `NixOs` modules and scripts for key generation and deployment.
The use of `Nix` makes the process easy to reproduce or introduce into a CI/CD pipeline.
The package consists of:

- `NixOs` module simplifying the definition of stake pool nodes
- a deployment script for every one of your nodes

and importantly a documentation and an example that ties the process together.
