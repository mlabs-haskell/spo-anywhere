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
  # Topology where every peer has single access point. TODO: allow to overwrite
  mkBlockProducerTopology = relayAddrs:
    toFile "topology.json" (
      toJSON
      {
        localRoots =
          map (
            addr: {
              accessPoints = [addr];
              advertise = false;
              valency = 1;
            }
          )
          relayAddrs;
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
      enable = mkEnableOption "Enable block producer cardano-node with some defaults.";
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
      key-paths.node-kes-skey = mkOption {
        type = types.path;
        description = ''
          File path to a node KES private key file.
          Give the file 400 permission for the `cardano-node` user.
          !Warning!: Don't provide a derivation as then the key is public.
        '';
      };
      key-paths.node-vrf-skey = mkOption {
        type = types.path;
        description = ''
          File path to a node VRF private key file.
          Give the file 400 permission for the `cardano-node` user.
          !Warning!: Don't provide a derivation as then the key is public.
        '';
      };
      key-paths.node-opcert-cert = mkOption {
        type = types.path;
        description = ''
          File path to a node operational certificate private key file.
          Give the file 400 permission for the `cardano-node` user.
          !Warning!: Don't provide a derivation as then the key is public.
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
      # address = "0.0.0.0";
      inherit (cfg) environment;
      topology = mkBlockProducerTopology cfg.relayAddrs;
      nodeConfig =
        config.services.cardano-node.environments.${config.services.cardano-node.environment}.nodeConfig
        // {
          hasPrometheus = [config.services.cardano-node.hostAddr 12798];
          # ShelleyGenesisFile = pkgs.writeText "my-file" ''Contents of File'';
        };
      # Keys.
      # [Idea1]: These options can be set from a "node-keys" module that works on top of the secrets module like agenix
      # [Note2 (node-keys)]: It turned out the secret can't be provided by derivation because cardano-node complains.
      #                      Solution provide in `etc` with copy mode (see [test/block-producer.nix]).
      #
      # Setting these should allow block production:
      kesKey = cfg.key-paths.node-kes-skey;
      vrfKey = cfg.key-paths.node-vrf-skey;
      operationalCertificate = cfg.key-paths.node-opcert-cert;
      # These are likely byron leftovers:
      # signingKey = null;
      # delegationCertificate = null;
    };
    # restart after process exits? i GUESS poeple do this in tests
    # systemd.services.cardano-node.serviceConfig.Restart = lib.mkForce "no";
  };
}
