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
      # Keys.
      # [Idea1]: These options can be set from a "node-keys" module that works on top of the secrets module like agenix
      # [Note2 (node-keys)]: It turned out the secret can't be provided by derivation because cardano-node complains.
      #        But if the secret is to be provided dynamically we might already just utilize agenix. I used agenix directly, would be better not to.
      # 
      # Setting these should allow block production:
      kesKey = config.age.secrets.node-kes-skey.path;
      vrfKey = config.age.secrets.node-vrf-skey.path;
      operationalCertificate = config.age.secrets.node-opcert-cert.path;
      # These are likely byron leftovers: 
      # signingKey = null;
      # delegationCertificate = null;
    };
    # restart after process exits? i GUESS poeple do this in tests
    # systemd.services.cardano-node.serviceConfig.Restart = lib.mkForce "no";
  };
}
