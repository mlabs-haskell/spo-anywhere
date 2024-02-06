{inputs, ...}: {
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.services.relay-node;

  # [{address : str, port : int}] -> topology file derivation
  # mimicks topology.json format
  mkBlockProducerTopology = relayAddrs:
    toFile "topology.json" (
      toJSON
      {
        localRoots = [
          {
            accessPoints = relayAddrs;
            advertise = false;
            valency = length relayAddrs;
          }
        ];
        publicRoots = [
          {
            accessPoints = [
            ];
            advertise = false;
          }
        ];
        useLedgerAfterSlot = -1;
      }
    );
in {
  imports = [
    inputs.cardano-node.nixosModules.cardano-node
  ];

  options = {
    services.relay-node = {
      enable = mkEnableOption "Enable relay cardano-node with some defaults.";
      environment = mkOption {
        type = types.enum (attrNames config.services.cardano-node.environments);
        default = "preprod";
        description = ''
          environment node will connect to
        '';
      };
      localAddrs = mkOption {
        type = with types; listOf attrs;
        description = ''
          Addresses to our other relay nodes and the block producer nodes. Will be added to nodes local roots. Provided as a list of { address : _, port : _ } attribute sets.
        '';
        example = ''
          [
            {
              address = "x.x.x.x";
              port = 3000;
            }
            {
              address = "y.y.y.y";
              port = 3000;
            }
          ]
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.cardano-node = {
      enable = true;
      port = 3001;
      hostAddr = "127.0.0.1";
      inherit (cfg) environment;
      topology = builtins.trace (config.services.cardano-node.environments.${config.services.cardano-node.environment}.topology) (mkBlockProducerTopology cfg.relayAddrs);
      nodeConfig =
        config.services.cardano-node.environments.${config.services.cardano-node.environment}.nodeConfig
        // {
          hasPrometheus = [config.services.cardano-node.hostAddr 12798];
        };
    };
    # restart after process exits? i GUESS poeple do this in tests
    # systemd.services.cardano-node.serviceConfig.Restart = lib.mkForce "no";
  };
}
