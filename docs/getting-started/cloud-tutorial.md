Read the Cardano documentation on how to [Oparate a Stake Pool](https://developers.cardano.org/docs/operate-a-stake-pool/).

This tutorial will guide you through deploying a stake pool to a cloud host using spo-anywhere.

### Clout Host

A cloud host is required as the target of deployment. We tested AWS, DigitalOcean and Hetzner with Ubuntu 24.04.

Creeate a cloud host for the block producer node in the cloud console, API, or via IaC tools such as [OpenTofu](https://opentofu.org/). The following requirements should be met:

- At least 4GB RAM
- Ubuntu 24.04
- SSH public key authentication configured for `root` user.

In the case of public testnets and mainnet, there may be additional requirements, such as more RAM and disk space.

Note down the IP address of the host. As an example, we will use an AWS host at IP `12.34.56.78`. Verify that SSH works:

```bash
ssh root@12.34.56.78
...
# press Ctrl+D to exit
```

### Start new project with flake template

Follow the [installation instructions](installation.md).

A great way to to get started is to use the [flake template](https://zero-to-nix.com/concepts/flakes#templates) provided by **spo-anywhere**. Here's how to start a new project using the `cloud` template:

```bash
mkdir myproject
cd myproject
nix flake init --template github:mlabs-haskell/spo-anywhere#cloud
```

### Configure

Edit `configuration.nix`. Update your SSH public key and IP address by changing the following lines:

```nix
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-..." ];
```

```nix
      target = "root@12.34.56.78";
```

For this tutorial, we will use testing private keys included with the project and configured by default, which are suitable for testing but should not be used for public networks. For details on how to generate and configure different keys, see [Configure Pool](../usage/configure-pool.md) and [Generate Keys](../usage/generate-keys.md).

### Install

Install NixOS and start configuration with block producer node:

```bash
nix run .#install
```

### Check

SSH into the machine and check the cardano-node logs:

```bash
ssh root@12.34.56.78
journalctl -e -u cardano-node
```

When blocks are produced, logs like this should show up:

```
TODO EXAMPLE
```

For public networks it may be necessary to [register the pool](../usage/register-the-pool.md) first.

### Deploy

To modify the configuration, edit e.g. `configration.nix` and deploy it with a [deployment tool](https://github.com/nix-community/awesome-nix?tab=readme-ov-file#deployment-tools), e.g. using `nixos-rebuild`:

```
nix run nixpkgs#nixos-rebuild -- switch --flake .#spo-node --target-host root@12.34.56.78
```

### Cloud Providers

Cloud provider support is provided by [srvos](https://github.com/nix-community/srvos).

To use a different cloud provider, edit `flake.nix` and replace `nixosModules.hardware-amazon` with one of the modules listed in the [srvos docs](https://nix-community.github.io/srvos/nixos/hardware/), eg:

```nix
nixosModules.hardware-hetzner-cloud
```

Then follow this tutorial from the beginning to provision, configure and install a host.

### Customize

To learn more, browse available [NixOS options in nixpkgs](https://search.nixos.org/options) and [NixOS options provided by spo-anywhere](../reference/module-options/spo-anywhere) (see other modules in the menu on the left). You can add these options to `configuration.nix` to configure the system and then deploy as above.

### Public Networks

For public networks, a few more things need to be considered. Here is a partial list:

- an offline (airgapped) node should used for generating keys and signing transactions
- a redundat set of relay nodes should be used to connect the block producer node to the network
- the block producer node should be connected to the relay nodes via private networking (cloud provider dependent or VPN)
- network security including firewalls, VPNs and jump hosts have to be configured

These are out of scope for this tutorial. A good way to get started deploying `cardano-node` hosts and networks is with [cardano.nix](https://github.com/mlabs-haskell/cardano.nix).

Read the Cardano documentation on how to [Oparate a Stake Pool](https://developers.cardano.org/docs/operate-a-stake-pool/) for more information.
