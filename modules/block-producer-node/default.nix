{inputs, ...}: {
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with builtins; let
  commonLib = inputs.iohkNix.lib;
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
          # Use Journald output:
          setupScribes = [
            {
              scKind = "JournalSK";
              scName = "cardano";
              scFormat = "ScText";
            }
          ];
          defaultScribes = [
            [
              "JournalSK"
              "cardano"
            ]
          ];
        };
    };
    # restart after process exits? i GUESS poeple do this in tests
    # systemd.services.cardano-node.serviceConfig.Restart = lib.mkForce "no";

    # services.cardano-submit-api = {
    #   enable = true;
    #   port = 8101;
    #   network = "mainnet";
    #   socketPath = config.services.cardano-node.socketPath 0;
    # };
    # systemd.services.cardano-submit-api.serviceConfig.SupplementaryGroups = "cardano-node";
  };
  # testScript = ''
  #   start_all()
  #   machine.wait_for_unit("cardano-node.service")
  #   machine.succeed("stat /run/cardano-node")
  #   machine.succeed("stat /run/cardano-node/node.socket")
  #   machine.wait_for_open_port(12798)
  #   machine.wait_for_open_port(3001)
  #   machine.succeed("systemctl status cardano-node")
  #   # FIXME reenable and check the cli syntax when https://github.com/input-output-hk/cardano-node/pull/4664 is merged
  #   #machine.succeed(
  #   #    "${cardanoNodePackages.cardano-cli}/bin/cardano-cli ping -h 127.0.0.1 -c 1 -q --json | ${jq}/bin/jq -c"
  #   #)
  #   machine.wait_for_open_port(8101)
  #   machine.succeed("systemctl status cardano-submit-api")
  # '';
}
