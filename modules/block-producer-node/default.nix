{cardano-node, ...}: {
  config,
  lib,
  ...
}: let
  cfg = config.spo-anywhere.node;
in
  with lib;
  with types; {
    imports = [
      cardano-node.nixosModules.cardano-node
    ];

    # TODO consider not using a wrapper module if it's not necessary (we'll see in the future as the project shapes up)
    # karol: ^ wrapper module seems not necessary, but I'd prefer to define it nevertheless
    #        as a mean of nudging the user into how to consume the upstream module (a kind of documentation for a complicated services.cardano-node module).
    #        As an example: It took us both a while to realize what differentiates a block producer from a relay - we can make it obvious for users of the wrapper.
    #        Added with a demo usage and we're set.

    options = {
      spo-anywhere.node = {
        enable = mkEnableOption "Enable cardano-node with some defaults. Provide necessary keys to run as a block producer.";

        # need to split from the rest of configs as this differentiates between a block producer and a relay
        block-producer-key-path = lib.mkOption {
          type = nullOr path;
          description = "Path to the block producer keys directory. Warning: Secrets, don't provide /nix/store paths here.";
        };

        configFilesPath = lib.mkOption {
          type = lib.types.path;
          description = "Path to the network configuration directory";
        };
      };
    };

    config = lib.mkIf cfg.enable {
      services.cardano-node = mkMerge [
        {
          enable = true;
          port = 3001;
          hostAddr = "127.0.0.1"; # We don't want to expose the block producer
          nodeConfigFile = "${cfg.configFilesPath}/configuration.yaml";
          topology = "${cfg.configFilesPath}/topology-spo-1.json";
        }
        (mkIf (cfg.block-producer-key-path != null) {
          signingKey = "${cfg.block-producer-key-path}/byron-gen-command/delegate-keys.000.key";
          delegationCertificate = "${cfg.block-producer-key-path}/byron-gen-command/delegation-cert.000.json";
          vrfKey = "${cfg.block-producer-key-path}/pools/vrf1.skey";
          kesKey = "${cfg.block-producer-key-path}/pools/kes1.skey";
          operationalCertificate = "${cfg.block-producer-key-path}/pools/opcert1.cert";
        })
      ];
    };
  }
