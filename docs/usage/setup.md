## Installation

Follow [this guide](https://zero-to-nix.com/start/install) to Install nix with [flakes](https://nix.dev/concepts/flakes.html) enabled.

### Binary cache

You can optionally use this project's binary cache to skip building software and download it instead. Edit `/etc/nix/nix.conf` (or related settings in NixOS config) and merge the new values separated by spaces into the options:

```
substituters = ...  https://cache.staging.mlabs.city/spo-anywhere
trusted-public-keys = ... spo-anywhere:bmI58BmXnmeuAtMKbm3qhwiJ1RALMfo6cDwncfaGa6Q=
```

## Start new project from flake

Create a new directory, enter it, and initialize a new project form the spo-anywhere flake template.

```sh
mkdir my-spo
cd my-spo
nix flake init --template github:mlabs-haskell/spo-anywhere
```

Check that the installation script starts:

```sh
nix run .#install -- -h
```

## Cloud host

Prepare a cloud host and make sure you can reach it via ssh:

```sh
ssh
```
