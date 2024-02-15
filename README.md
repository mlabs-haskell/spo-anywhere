# SPO-anywhere

Tool leveraging on [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) to deploy Cardano stake pools on any cloud provider.

## Setup

Install nix and enable flakes, eg. with [Determinate nix installer](https://github.com/DeterminateSystems/nix-installer).

Use the project's binary cache to skip builds. Edit `/etc/nix/nix.conf` (or related settings in NixOS config) and merge the new values separated by spaces into the options:

```
substituters = ...  https://cache.staging.mlabs.city/spo-anywhere
trusted-public-keys = ... spo-anywhere:bmI58BmXnmeuAtMKbm3qhwiJ1RALMfo6cDwncfaGa6Q=
```

Don't edit `~/.config/nix/nix.conf` in your home directory. Don't add users to `trusted-users` because it is [insecure](https://nixos.org/manual/nix/stable/command-ref/conf-file.html?highlight=trusted-user#conf-trusted-users).

### Development Shell

`SPO-anywhere` provides a devshell that includes some useful tools and aliases:

```
❯ nix develop
...
❄️ Welcome to the spo-anywhere devshell ❄️
...
[Tools]

  build-all  - Build all the checks
  check      - Alias of `nix flake check`
  fmt        - Format the source tree
...
```

A `.envrc` is also provided, using [direnv]() and [nix-direnv](https://github.com/nix-community/nix-direnv) is suggested.

## License information

`cardano.nix` released under terms of [Apache-2.0](LICENSES/Apache-2.0.txt) license.
