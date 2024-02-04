{inputs, ...}: {
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.services.block-producer-node;

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
    # inputs.cardano-node.nixosModules.cardano-submit-api
  ];

  options = {
    services.block-producer-node = {
      enable = mkEnableOption "Enable cardano-node with some defaults.";
      environment = mkOption {
        type = types.enum (attrNames config.services.cardano-node.environments);
        default = "preprod";
        description = ''
          environment node will connect to
        '';
      };
      relayAddrs = mkOption {
        type = with types; listOf attrs;
        description = ''
          Addresses to our relay nodes. Will be added to nodes local roots. Provided as a list of { address : _, port : _ } attribute sets.
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
      # systemdSocketActivation = fase;
      port = 3001;
      hostAddr = "127.0.0.1";
      inherit (cfg) environment;
      topology = mkBlockProducerTopology cfg.relayAddrs;
      nodeConfig =
        config.services.cardano-node.environments.${config.services.cardano-node.environment}.nodeConfig
        // {
          hasPrometheus = [config.services.cardano-node.hostAddr 12798];
        };
      # keys. Idea: These options can be set from a "node-keys" module that works on top of the secrets module like agenix
      # signingKey = null;
      # delegationCertificate = null;
      # Setting these should allow block production:
      kesKey = ./hardcoded-keys/kes.skey;
      vrfKey = ./hardcoded-keys/vrf.skey;
      operationalCertificate = ./hardcoded-keys/opcert.cert;
    };
    # restart after process exits? i GUESS poeple do this in tests
    # systemd.services.cardano-node.serviceConfig.Restart = lib.mkForce "no";
  };
}
