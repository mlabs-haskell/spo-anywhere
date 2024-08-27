Development is supported on linux systems. Virtual machines are run with `qemu` so `kvm` is recommended. Follow the [installation guide](https://mlabs-haskell.github.io/cardano.nix/getting-started/installation/) to set up nix.

## Development Shell

`spo-anywhere` provides a devshell that includes various tools to build, test, run and update the project:

```
$ nix develop
...
❄️ Welcome to the SPO-anywhere devshell ❄️

[Tools]

  build-all - Build all the checks
  check     - Alias of `nix flake check`
  fmt       - Format the source tree

[[general commands]]

  menu      - prints this menu

[testing]

  run-test  - Run tests
```

A `.envrc` file is also provided, using [direnv](https://direnv.net/) and [nix-direnv](https://github.com/nix-community/nix-direnv) is suggested.

### Running Integration Tests

From the devshell you can run integration tests with `run-test`, for example the following will start two `cardano-node`'s and on a testnet, spend some transaction and wait for its inclusion in a minted block.

```
run-test relay-node
```
