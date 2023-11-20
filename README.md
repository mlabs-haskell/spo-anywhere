# SPO-anywhere

Tool leveraging on [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) to deploy Cardano stake pools on any cloud provider.

## Shell

`SPO-anywhere` provides a shell that includes some useful aliases:

- `fmt` formats the entire repository using [treefmt](https://github.com/numtide/treefmt)
- `build-all` builds all the flake's outputs using [devour-flake](https://github.com/srid/devour-flake)
- `check` simply stands for `nix flake check`

A `.envrc` is also provided, using [direnv]() and [nix-direnv](https://github.com/nix-community/nix-direnv) is highly suggested.
