{ cardano-node, ... }@inputs: {
  config,
  lib,
  ...
}: let
  cfg = config.services.block-producer-node;
in {
  imports = [
    cardano-node.nixosModules.cardano-node
  ];

  # TODO consider not using a wrapper module if it's not necessary (we'll see in the future as the project shapes up)

  options = {
    services.block-producer-node = {
      enable = lib.mkEnableOption "Enable block producer cardano-node with some defaults.";
      configFilesPath = lib.mkOption {
        type = lib.types.path;
        description = "Path to the network configuration directory";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.cardano-node = {
      enable = true;
      port = 3001;
      hostAddr = "127.0.0.1"; # We don't want to expose the block producer
      nodeConfigFile = "${cfg.configFilesPath}/configuration.yaml";
      vrfKey = "${cfg.configFilesPath}/pools/vrf1.skey";
      kesKey = "${cfg.configFilesPath}/pools/kes1.skey";
      operationalCertificate = "${cfg.configFilesPath}/pools/opcert1.cert";
      topology = "${cfg.configFilesPath}/topology-spo-1.json";
      signingKey = "${cfg.configFilesPath}/byron-gen-command/delegate-keys.000.key";
      delegationCertificate = "${cfg.configFilesPath}/byron-gen-command/delegation-cert.000.json";
    };
  };
}
