{inputs}: _: {
  spo-anywhere.tests = {
    block-producer = let
      # common module between block producer and relays
      common = {
        config,
        pkgs,
        ...
      }: {
        networking = {
          useNetworkd = true;
          useDHCP = false;
          firewall = {
            enable = false;
            # allowedTCPPorts = [ 3001 ];
          };
        };
        virtualisation = {
          # Virtual networks to which the VM is connected.
          # Each number «N» in this list causes the VM to have a virtual Ethernet interface attached to a separate virtual network
          # on which it will be assigned IP address 192.168.«N».«M», where «M» is the index of this VM in the list of VMs.
          vlans = [1];
          cores = 2;
          memorySize = 1024;
          writableStore = false;	  
        };
        environment = {
          systemPackages = [
            config.services.cardano-node.cardanoNodePackages.cardano-cli
            pkgs.lsof
            pkgs.nmap
            pkgs.python3
            pkgs.jq
          ];
        };
      };
    in {
      systems = ["x86_64-linux"];

      module = {
        name = "block producer starts";

        nodes = {
          producer = {pkgs, lib, ...}: {
            imports = [common];

	    systemd.tmpfiles.rules = [
	      # "C+ /etc/testnet - - - - ${./testnet-template}"
	      # "Z /etc/testnet 700 cardano-node cardano-node - ${./testnet-template}"
	      "C+ /etc/testnet - - - - ${../genesis-dir}"
	      "Z /etc/testnet 700 cardano-node cardano-node - ${../genesis-dir}"
	      "C+ /etc/stake-pool-keys - - - - ${../stake-pool-keys}"
	      "Z /etc/stake-pool-keys 755 cardano-node cardano-node - ${../stake-pool-keys}"
	    ];
	    
	    services.cardano-node = {
	      enable = true;
	      nodeConfigFile = "/etc/testnet/node-config.json";
	      vrfKey = "/etc/testnet/delegate-keys/shelley.000.vrf.skey";
	      kesKey = "/etc/testnet/delegate-keys/shelley.000.kes.skey";
	      operationalCertificate = "/etc/testnet/delegate-keys/shelley.000.opcert.json";
	      topology = "/etc/testnet/topology-empty-p2p.json";
	    };

	    systemd.services.cardano-node.preStart = let
	      cardano-cli = inputs.cardano-node.packages.${pkgs.system}.cardano-cli;
	    in ''
              NOW=$(date +%s)
              ${lib.getExe pkgs.yq-go} e -i ".startTime = $NOW" /etc/testnet/byron-genesis.json
              BYRON_GENESIS_HASH=$(${lib.getExe cardano-cli} byron genesis print-genesis-hash --genesis-json /etc/testnet/byron-genesis.json)
              ${pkgs.yq-go}/bin/yq e -i ".ByronGenesisHash = \"$BYRON_GENESIS_HASH\"" /etc/testnet/node-config.json
            '';

	    environment.systemPackages = [
	      (pkgs.writeShellApplication {
		name = "test-transactions";
		runtimeInputs = [
		  inputs.cardano-node.packages.${pkgs.system}.cardano-cli
		  pkgs.jq
		  # inputs.cardano-world.${pkgs.system}.automation.jobs.move-genesis-utxo
		];
		checkPhase = "";
		text = ''
		  export CARDANO_NODE_SOCKET_PATH=/run/cardano-node/node.socket
		  cardano-cli query tip --testnet-magic 42
		  cardano-cli query utxo --whole-utxo --testnet-magic 42

                  # Register stake pools
                  export PAYMENT_KEY=/etc/testnet/utxo-keys/rich-utxo
                  export CHANGE_ADDRESS=$(cardano-cli address build --payment-verification-key-file "$PAYMENT_KEY".vkey --testnet-magic 42)
                  export START_INDEX=1
                  export NUM_POOLS=2
		  export END_INDEX=$(("$START_INDEX" + "$NUM_POOLS"))
                  export WITNESSES=$(("$NUM_POOLS" * 2 + 1))
		  export STAKE_POOL_OUTPUT_DIR="/etc/stake-pool-keys"
                  export POOL_PLEDGE="1000000000000"

                  # Generate transaction
                  export TXIN=$(
                    cardano-cli query utxo \
                      --whole-utxo \
                      --testnet-magic 42 \
                      --out-file /dev/stdout \
                      | jq -r 'to_entries[0] | .key'
                  )

                  # Generate arrays needed for build/sign commands
                  export BUILD_TX_ARGS=()
                  export SIGN_TX_ARGS=()

                  for ((i="$START_INDEX"; i < "$END_INDEX"; i++)); do
                    STAKE_POOL_ADDR=$(
                      cardano-cli address build \
                      --payment-verification-key-file "$PAYMENT_KEY".vkey \
                      --stake-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-stake.vkey \
                      --testnet-magic 42
                    )
                    BUILD_TX_ARGS+=("--tx-out" "$STAKE_POOL_ADDR+$POOL_PLEDGE")
                    BUILD_TX_ARGS+=("--certificate-file" "$STAKE_POOL_OUTPUT_DIR/sp-$i-owner-registration.cert") # These 3 files shouldn't be in this directory
                    BUILD_TX_ARGS+=("--certificate-file" "$STAKE_POOL_OUTPUT_DIR/sp-$i-registration.cert")
                    BUILD_TX_ARGS+=("--certificate-file" "$STAKE_POOL_OUTPUT_DIR/sp-$i-owner-delegation.cert")
                    SIGN_TX_ARGS+=("--signing-key-file" "$STAKE_POOL_OUTPUT_DIR/sp-$i-cold.skey")
                    SIGN_TX_ARGS+=("--signing-key-file" "$STAKE_POOL_OUTPUT_DIR/sp-$i-owner-stake.skey")
                  done

                  cardano-cli transaction build --shelley-era \
                    --tx-in "$TXIN" \
                    --change-address "$CHANGE_ADDRESS" \
                    --witness-override "$WITNESSES" \
                    "''${BUILD_TX_ARGS[@]}" \
                    --testnet-magic 42 \
                    --out-file tx-pool-reg.txbody

                  echo QUI
                  exit 1

                  cardano-cli transaction sign \
                    --tx-body-file tx-pool-reg.txbody \
                    --out-file tx-pool-reg.txsigned \
                    --signing-key-file "$PAYMENT_KEY".skey \
                    "''${SIGN_TX_ARGS[@]}"

                  cardano-cli transaction submit --testnet-magic 42 --tx-file tx-pool-reg.txsigned

                  # Move initial fund

                  export PAYMENT_ADDRESS=addr_test1vpaeyyjrlmxcjk23mflkn7nqaxj6m07zc6zdh45yfjnjqcgav9jcj
		  export BYRON_SIGNING_KEY=/etc/testnet/utxo-keys/shelley.000.skey

                  BYRON_UTXO=$(
                    cardano-cli query utxo \
                      --whole-utxo \
                      --testnet-magic 42 \
                      --out-file /dev/stdout \
                    | jq '
                      to_entries[]
                      | {"txin": .key, "address": .value.address, "amount": .value.value.lovelace}
                      | select(.amount > 0)
                    '
                  )
                  export FEE=200000
                  export SUPPLY=$(echo "$BYRON_UTXO" | jq -r '.amount - 200000')
                  export BYRON_ADDRESS=$(echo "$BYRON_UTXO" | jq -r '.address')
                  export TXIN=$(echo "$BYRON_UTXO" | jq -r '.txin')

                  cardano-cli transaction build-raw --shelley-era \
                    --tx-in "$TXIN" \
                    --tx-out "$PAYMENT_ADDRESS+$SUPPLY" \
                    --fee "$FEE" \
                    --out-file tx-byron.txbody

                  cardano-cli transaction sign \
                    --tx-body-file tx-byron.txbody \
                    --out-file tx-byron.txsigned \
                    --address "$BYRON_ADDRESS" \
                    --signing-key-file "$BYRON_SIGNING_KEY"

                  cardano-cli transaction submit --testnet-magic 42 --tx-file tx-byron.txsigned
                '';
              })];
	    };
	};

        testScript = ''
          start_all()
          producer.wait_for_unit("cardano-node.service")
          producer.wait_for_open_port(3001)  # node
          producer.succeed("stat /run/cardano-node")
          # producer.succeed("stat /run/cardano-node/node.socket")
          # producer.succeed("systemctl status cardano-node")
          print(producer.succeed("test-transactions"))

          # from time import sleep
          # sleep(1000000)  
        '';
      };
    };
  };
}
