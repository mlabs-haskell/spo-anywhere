{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    apps.generate-testnet-config.program = pkgs.writeShellApplication {
      name = "generate-testnet-config";
      runtimeInputs = [config.flake-root.package];
      runtimeEnv = {
        NETWORK_MAGIC = "2";
        SECURITY_PARAM = "2160";
        NUM_SPO_NODES = "1";
        INIT_SUPPLY = "10000000000";
        SUPPLY = "16446744073709551615";
        MAX_SUPPLY = "18346744073709551615";
      };
      text = ''
               CONFIG="$(flake-root)"/tests/local-testnet-config
        START_TIME=$(date -d "now" +%s)  # irrelevant since we're going to change it just before starting the network

        echo "(Re-)generating configuration in $CONFIG"
        rm -rf "$CONFIG"
        mkdir -p "$CONFIG"

               cp "${./testnet-template}"/* "$CONFIG"/

        cardano-cli byron genesis genesis \
          --protocol-magic $NETWORK_MAGIC \
          --start-time "$START_TIME" \
          --k $SECURITY_PARAM \
          --n-poor-addresses 0 \
          --n-delegate-addresses $NUM_SPO_NODES \
          --total-balance $INIT_SUPPLY \
          --delegate-share 1 \
          --avvm-entry-count 0 \
          --avvm-entry-balance 0 \
          --protocol-parameters-file "$CONFIG/byron.genesis.spec.json" \
          --genesis-output-dir "$CONFIG/byron-gen-command"

        chmod 700 -R "$CONFIG"

        cardano-cli genesis create-staked --genesis-dir "$CONFIG" \
          --testnet-magic "$NETWORK_MAGIC" \
          --gen-pools 1 \
          --supply $SUPPLY \
          --supply-delegated $SUPPLY \
          --gen-stake-delegs 1 \
          --gen-utxo-keys 1 \
          --gen-genesis-keys 1

        jq --argjson maxSupply "$MAX_SUPPLY" --argjson secParam "$SECURITY_PARAM" '.maxLovelaceSupply = $maxSupply | .slotLength = 1 | .securityParam = $secParam | .activeSlotsCoeff = 0.05 | .securityParam = $secParam | .epochLength = 432000 | .updateQuorum =2 | .protocolParams.protocolVersion.major = 7 | .protocolParams.minFeeA = 44 | .protocolParams.minFeeB = 155381 | .protocolParams.minUTxOValue = 1000000 | .protocolParams.decentralisationParam = 0.7 | .protocolParams.rho = 0.003 | .protocolParams.tau = 0.2' "$CONFIG/genesis.json" > "$CONFIG/temp.json" && mv "$CONFIG/temp.json" "$CONFIG/genesis.json"
      '';
    };
  };
}
