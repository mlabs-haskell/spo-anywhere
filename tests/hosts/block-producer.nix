{inputs, ...}: let
  common = {
    config,
    pkgs,
    ...
  }: {
    networking = {
      firewall.enable = false; # Useful when running the test interactively
    };
    virtualisation = {
      cores = 2;
      memorySize = 1024;
      writableStore = false;
    };
    # Useful for debugging the test
    environment = {
      variables.CARDANO_NODE_SOCKET_PATH = "/run/cardano-node/node.socket";
      systemPackages = [
        config.services.cardano-node.cardanoNodePackages.cardano-cli
        pkgs.jq
      ];
    };
  };
in
  {
    pkgs,
    lib,
    ...
  }: {
    imports = [common];

    config = {
      # The cardano node requires that the configurations files and keys/certificates have the right permissions
      systemd.tmpfiles.rules = [
        "C+ /etc/testnet - - - - ${../local-testnet-config}"
        "Z /etc/testnet 700 cardano-node cardano-node - ${../local-testnet-config}"
      ];

      spo-anywhere.node = {
        enable = true;
        configFilesPath = "/etc/testnet";
        block-producer-key-path = "/etc/testnet";
      };

      # This is a workaround to set a new start time for the ephemeral testnet created by the test
      # This way the network will start from the slot 0
      systemd.services.cardano-node.preStart = ''
        NOW=$(date +%s -d "now + 5 seconds")
        ${lib.getExe pkgs.yq-go} e -i ".startTime = $NOW" /etc/testnet/byron-gen-command/genesis.json
      '';

      environment.systemPackages = [
        (import ./spend-utxo-testscript.nix {inherit inputs pkgs;})
      ];
    };
  }
