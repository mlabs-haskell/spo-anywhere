Read the Cardano documentation on how to [Oparate a Stake Pool](https://developers.cardano.org/docs/operate-a-stake-pool/).

This tutorial will guide you through deploying a stake pool to a cloud host using spo-anywhere.

### Clout Host

A cloud host is required as the target of deployment. We tested AWS, DigitalOcean and Hetzner with Ubuntu 24.04.

Creeate a cloud host for the block producer node in the cloud console, API, or via IaC tools such as [OpenTofu](https://opentofu.org/). The following requirements should be met:

- At least 4GB RAM
- Ubuntu 24.04
- SSH public key authentication configured for `root` user.

In the case of public testnets and mainnet, there may be additional requirements, such as more RAM and disk space.

Note down the IP address of the host. As an example, we will use a Hetzner Cloud host at IP `12.34.56.78`. Verify that SSH works:

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

Edit `target.nix`. Update your SSH public key and IP address by changing the following lines:

```nix
  users.users.root.openssh.authorizedKeys.keys = [ "ssh-..." ];

  spo-anywhere.install-script.target = "root@12.34.56.78";
```

For this tutorial, we will use testing private keys included with the project and configured by default, which are suitable for testing but should not be used for public networks. For details on how to generate and configure different keys, see [Configure Pool](../usage/configure-pool.md) and [Generate Keys](../usage/generate-keys.md).

### Install

Install NixOS and start configuration with block producer node:

```bash
nix run .#install -- --ssh-key <private-key-path>
```

### Check

SSH into the machine and check the cardano-node logs:

```bash
ssh root@12.34.56.78
journalctl -e -u cardano-node
```

When blocks are produced, logs like this should show up:

```
Jan 29 07:01:21 spo-anywhere-test cardano-node-start[938]: [spo-anyw:cardano.node.Forge:Info:52] [2025-01-29 07:01:21.00 UTC] fromList [("credentials",String "Cardano"),("val",Object (fromList [("block",String "61c5de2ece6ceee1fca8716a94d38875ca3ed23c8d7b16b23b2933fa8cd1bff4"),("blockNo",Number 30.0),("blockPrev",String "6af1f332aac4adc1ab42f19b4750a6f47844a627532444f2fdf85f2c2f0f14a7"),("kind",String "TraceForgedBlock"),("slot",Number 716.0)]))]
Jan 29 07:01:21 spo-anywhere-test cardano-node-start[938]: [spo-anyw:cardano.node.ChainDB:Notice:35] [2025-01-29 07:01:21.00 UTC] Chain extended, new tip: 61c5de2ece6ceee1fca8716a94d38875ca3ed23c8d7b16b23b2933fa8cd1bff4 at slot 716
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
nixosModules.hardware-amazon
```

You may also need to change `disko.nix` or remove it and configure `fileSystems` and `boot` directly.

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
