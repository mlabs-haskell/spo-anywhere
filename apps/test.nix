
{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    inputs',
    ...
  }: {
    packages.generate-genesis-and-keys = let
      emptyTopology = pkgs.writers.writeJSON "topology-empty-p2p.json" {
        localRoots = [
          {
            accessPoints = [];
            advertise = false;
            valency = 1;
          }
        ];
        publicRoots = [
          {
            accessPoints = [];
            advertise = false;
          }
        ];
        useLedgerAfterSlot = -1;
      };
    in
      pkgs.writeShellApplication {
        name = "generate-genesis-and-keys";
        runtimeInputs = [
          inputs.cardano-world.${system}.automation.jobs.gen-custom-node-config
          # inputs.cardano-world.${system}.automation.jobs.gen-custom-kv-config
        ];
        runtimeEnv = rec {
          IOHK_NIX = inputs.cardano-world.inputs.iohk-nix;
          TEMPLATE_DIR = "${IOHK_NIX}/cardano-lib/testnet-template";
          SECURITY_PARAM = 432;
          NUM_GENESIS_KEYS = 7;
          SLOT_LENGTH = 1000;
          TESTNET_MAGIC = 42;

          NUM_POOLS = 3;
          START_INDEX = 1;
          POOL_RELAY = "localhost";
          POOL_RELAY_PORT = 30002;
        };
        text = ''
          export GENESIS_DIR="''${PRJ_ROOT}/genesis-dir";
          rm -rf "$GENESIS_DIR"
          gen-custom-node-config

          cardano-cli address key-gen \
            --signing-key-file "$GENESIS_DIR"/utxo-keys/rich-utxo.skey \
            --verification-key-file "$GENESIS_DIR"/utxo-keys/rich-utxo.vkey

          cp ${emptyTopology} "''$GENESIS_DIR"/topology-empty-p2p.json

          export PAYMENT_KEY="''$GENESIS_DIR"/utxo-keys/rich-utxo
          export STAKE_POOL_OUTPUT_DIR="''${PRJ_ROOT}/stake-pool-keys"
          rm -rf "$STAKE_POOL_OUTPUT_DIR"

          echo "Pool pledge is defaulting to 1 million ADA"
          export POOL_PLEDGE="1000000000000"

          END_INDEX=$(("$START_INDEX" + "$NUM_POOLS"))

          mkdir -p "$STAKE_POOL_OUTPUT_DIR"

          # Generate wallet in control of all the funds delegated to the stake pools
          cardano-address recovery-phrase generate > "$STAKE_POOL_OUTPUT_DIR"/owner.mnemonic

          # Extract reward address vkey
          cardano-address key from-recovery-phrase Shelley < "$STAKE_POOL_OUTPUT_DIR"/owner.mnemonic \
            | cardano-address key child 1852H/1815H/"0"H/2/0 \
            | cardano-cli key convert-cardano-address-key --shelley-stake-key \
              --signing-key-file /dev/stdin --out-file /dev/stdout \
            | cardano-cli key verification-key --signing-key-file /dev/stdin \
              --verification-key-file /dev/stdout \
            | cardano-cli key non-extended-key \
              --extended-verification-key-file /dev/stdin \
              --verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-0-reward-stake.vkey

          for ((i="$START_INDEX"; i < "$END_INDEX"; i++)); do
            # Extract stake skey/vkey needed for pool registration and delegation
            cardano-address key from-recovery-phrase Shelley < "$STAKE_POOL_OUTPUT_DIR"/owner.mnemonic \
              | cardano-address key child 1852H/1815H/"$i"H/2/0 \
              | cardano-cli key convert-cardano-address-key --shelley-stake-key \
                --signing-key-file /dev/stdin \
                --out-file /dev/stdout \
              | tee "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-stake.skey \
              | cardano-cli key verification-key \
                --signing-key-file /dev/stdin \
                --verification-key-file /dev/stdout \
              | cardano-cli key non-extended-key \
                --extended-verification-key-file /dev/stdin \
                --verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-stake.vkey

            # Generate cold, vrf and kes keys
            cardano-cli node key-gen \
              --cold-signing-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-cold.skey \
              --verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-cold.vkey \
              --operational-certificate-issue-counter-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-cold.counter

            cardano-cli node key-gen-VRF \
              --signing-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-vrf.skey \
              --verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-vrf.vkey

            cardano-cli node key-gen-KES \
              --signing-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-kes.skey \
              --verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-kes.vkey

            # Generate opcert
            cardano-cli node issue-op-cert \
              --kes-period 0 \
              --kes-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-kes.vkey \
              --operational-certificate-issue-counter-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-cold.counter \
              --cold-signing-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-cold.skey \
              --out-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i".opcert

            # Generate stake registration and delegation certificate
            cardano-cli stake-address registration-certificate \
              --stake-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-stake.vkey \
              --out-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-registration.cert

            cardano-cli stake-address delegation-certificate \
              --cold-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-cold.vkey \
              --stake-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-stake.vkey \
              --out-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-delegation.cert

            # Generate stake pool registration certificate
            cardano-cli stake-pool registration-certificate \
              --testnet-magic "$TESTNET_MAGIC" \
              --cold-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-cold.vkey \
              --pool-cost 500000000 \
              --pool-margin 1 \
              --pool-owner-stake-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-owner-stake.vkey \
              --pool-pledge "$POOL_PLEDGE" \
              --single-host-pool-relay "$POOL_RELAY" \
              --pool-relay-port "$POOL_RELAY_PORT" \
              --pool-reward-account-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-0-reward-stake.vkey \
              --vrf-verification-key-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-vrf.vkey \
              --out-file "$STAKE_POOL_OUTPUT_DIR"/sp-"$i"-registration.cert
          done
        '';
      };
  };
}
