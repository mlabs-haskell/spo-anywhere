# Pledge amount in Lovelace
PLEDGE=1000000
# Pool cost per-epoch in Lovelace
COST=170000000
# Pool cost per epoch in percentage
MARGIN=0.1
# Preview network
TESTNET_MAGIC=2
# Metadata
METADATA_FILE=pool-metadata.json
echo '{
  "name": "Test",
  "description": "Test",
  "ticker": "TEST",
  "homepage": "https://mlabs-haskell.github.io/spo-anywhere"
}' > $METADATA_FILE
METADATA_HASH=`cardano-cli latest stake-pool metadata-hash --pool-metadata-file pool-metadata.json`
RELAY_IPV4="87.227.245.188"
RELAY_HOST="static.87.227.245.188.clients.your-server.de"
RELAY_PORT=3000
STAKE_DEPOSIT_AMOUNT=2000000
