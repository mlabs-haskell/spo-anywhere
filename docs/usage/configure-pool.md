## Configure pool

Define the nixos configuration:

```nix
nixosModules.pool = {
  config = {

      spo-anywhere = {
        node = {
          enable = true;
          # optional, alternatively define configurations directly in `services.cardano-node`
          configFilesPath = "/etc/spo/configs";
          block-producer-key-path = "/var/lib/spo";
        };
      };

      # overwrite as desired
      services.cardano-node = {
        environment = "mainnet";
        # ...
      };

      # define the disk partitioning
      disko.devices = {
        # ...
      };

      # remaining options to fully configure the system
      networking.hostName = "my-pool";
      # ...
  };
};
```

for full examples see [flake template](../../template/). Check module reference in these docs.
Notice that the disko part of the configuration defining the disk partitioning is necessary.
Node config can be defined in many ways, but it has to result in node config and topology defined.
Both can be defined with optional `spo-anywhere.node.configFilesPath`.
Topology can be defined with i.e. `services.cardano-node.[producers|publicProducers|topology]`
and the node configuration can be defined i.e. with `services.cardano-node.[environment|nodeConfig]` and specific settings overwritten with many other options.
