{inputs, pkgs}: (pkgs.writeShellApplication {
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
        })