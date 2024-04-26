{inputs}: _: {
  spo-anywhere.tests = {
    block-producer = let
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
    in {
      systems = ["x86_64-linux"];

      module = {
        name = "block producer";

        nodes = {
          producer = {pkgs, lib, ...}: {
            imports = [common];

	    systemd.tmpfiles.rules = [
	      "C+ /etc/testnet - - - - ${./local-testnet-config}"
	      "Z /etc/testnet 700 cardano-node cardano-node - ${../local-testnet-config}"
	    ];
	    
	    services.cardano-node = {
	      enable = true;
	      nodeConfigFile = "/etc/testnet/configuration.yaml";
	      vrfKey = "/etc/testnet/pools/vrf1.skey";
	      kesKey = "/etc/testnet/pools/kes1.skey";
	      operationalCertificate = "/etc/testnet/pools/opcert1.cert";
	      topology = "/etc/testnet/topology-spo-1.json";
              signingKey = "/etc/testnet/byron-gen-command/delegate-keys.000.key";
              delegationCertificate = "/etc/testnet/byron-gen-command/delegation-cert.000.json";
	    };

	    # This is a workaround to set a new start time for the ephemeral testnet created by the test
	    # This way the network will start from the slot 0
	    systemd.services.cardano-node.preStart = ''
              NOW=$(date +%s -d "now + 5 seconds")
              ${lib.getExe pkgs.yq-go} e -i ".startTime = $NOW" /etc/testnet/byron-gen-command/genesis.json
            '';

	    environment.systemPackages = [
	      (pkgs.writeShellApplication {
		name = "spend-utxo";
		runtimeInputs = [
		  inputs.cardano-node.packages.${pkgs.system}.cardano-cli
		  pkgs.jq
		];
		runtimeEnv.CARDANO_NODE_SOCKET_PATH = "/run/cardano-node/node.socket";
		text = ''
		  trap 'echo "# $BASH_COMMAND"' DEBUG

		  cardano-cli query tip --testnet-magic 2
		  cardano-cli query utxo --whole-utxo --testnet-magic 2

                  cardano-cli address build \
                    --payment-verification-key-file "/etc/testnet/utxo-keys/utxo1.vkey" \
                    --out-file "/tmp/wallet.addr" \
                    --testnet-magic 2 

                  cardano-cli query utxo \
                    --testnet-magic 2 \
                    --address "$(cat "/tmp/wallet.addr")" \
                    --out-file "/tmp/utxos.json"

                  TXIN=$(jq "keys[0]" "/tmp/utxos.json" --raw-output)
                  SEND_AMT=3000000
		  WALLET_ADDR="$(cat /tmp/wallet.addr)"
                  TXOUT="$(cat "/tmp/wallet.addr")+$SEND_AMT"

                  cardano-cli transaction build \
		    --testnet-magic 2 \
		    --change-address "$WALLET_ADDR" \
		    --tx-in "$TXIN" \
		    --tx-out "$TXOUT" \
		    --out-file "/tmp/tx.body" \
		    --witness-override 2

                  cardano-cli transaction sign \
		    --tx-body-file "/tmp/tx.body" \
		    --signing-key-file "/etc/testnet/utxo-keys/utxo1.skey" \
		    --testnet-magic 2 \
		    --out-file "/tmp/tx.signed"

                  cardano-cli query utxo \
                    --testnet-magic 2 \
		    --address "$WALLET_ADDR" \
                    --out-file=/dev/stdout

                  echo "There is only 1 UTXO owned by the wallet"
		  cardano-cli query utxo \
                    --testnet-magic 2 \
		    --address "$WALLET_ADDR" \
                    --out-file=/dev/stdout \
		  | jq -e "length == 1"

                  cardano-cli transaction submit \
		    --tx-file "/tmp/tx.signed" \
		    --testnet-magic 2

                  while true; do
		    CURRENT_BLOCK="$(cardano-cli query tip --testnet-magic 2 | jq '.block // 0')"
		    if [ "$CURRENT_BLOCK" -eq 1 ]; then
                      echo "Waiting for a block to be mined..."
		      break
		    fi
		    sleep 5
		  done
                  
                  echo "Now there are 2 UTXOs"
		  cardano-cli query utxo \
                    --testnet-magic 2 \
		    --address "$WALLET_ADDR" \
                    --out-file=/dev/stdout \
		  | jq -e "length == 2"
                '';
              })];
	    };
	};

        testScript = ''
          start_all()
          producer.wait_for_unit("cardano-node.service")
          producer.wait_for_open_port(3001)
          producer.succeed("stat /run/cardano-node")
          producer.succeed("stat /run/cardano-node/node.socket")
          producer.succeed("systemctl status cardano-node")
          print(producer.succeed("spend-utxo"))
        '';
      };
    };
  };
}
