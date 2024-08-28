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

for full examples see [flake template](../../template/). Check module reference in these docs. Notice that the disko part of the configuration defining the disk partitioning is necessary.
