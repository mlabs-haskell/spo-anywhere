{
  pkgs,
  lib,
  inputs,
  ...
}: {
  networking.hostName = "spo-node";

  system.stateVersion = "24.11";

  services.cardano-node = {
    environment = "preview";
  };

  spo-anywhere = {
    node = {
      enable = true;
      configFilesPath = "/etc/testnet";
      block-producer-key-path = "/etc/testnet";
    };
    install-script = {
      enable = true;
    };
  };

  # Copy local testnet configuration files and allow access
  systemd.tmpfiles.rules = [
    "C+ /etc/testnet - - - - ${inputs.spo-anywhere}/tests/local-testnet-config"
    "Z /etc/testnet 700 cardano-node cardano-node - ${inputs.spo-anywhere}/tests/local-testnet-config"
  ];

  # This is a workaround to set a new start time for the ephemeral testnet created by the test
  # This way the network will start from the slot 0
  systemd.services.cardano-node = {
    serviceConfig.PermissionsStartOnly = true;
    preStart = ''
      NOW=$(date +%s -d "now + 5 seconds")
      chmod +w /etc/testnet/byron-gen-command/genesis.json
      ${lib.getExe pkgs.yq-go} e -i ".startTime = $NOW" /etc/testnet/byron-gen-command/genesis.json
    '';
  };
}
