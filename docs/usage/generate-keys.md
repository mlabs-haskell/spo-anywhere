## Generate Keys

TODO blah we need a bunch of keys


<!-- We need 3 keys:

- VRF key
- KES key
- Operational certificate

For the breakdown read [cardano key pairs](https://developers.cardano.org/docs/operate-a-stake-pool/cardano-key-pairs/). Notice that operational certificate is derived from node cold key and is valid for a period of time, so the cold key is also needed for maintenance.

For guide on key generation follow [operate a stake pool](https://developers.cardano.org/docs/operate-a-stake-pool/block-producer-keys). You need `cardano-cli` which can be obtained for example from the projects shell with:

```bash
nix develop .#spo-shell
```

For the next steps create a folder `spo-keys`:

```
spo-keys/
  vrf.skey
  kes.skey
  opcert.cert
``` -->


### Variables

We set up a bunch of variables for the key generation. This depends on the network being used.

TODO where to get the values

```bash
# Pledge amount in Lovelace
export PLEDGE=1000000
# Pool cost per-epoch in Lovelace
export COST=170000000
# Pool cost per epoch in percentage
export MARGIN=0.1
# Preview network
export TESTNET_MAGIC=2
# Metadata
export METADATA_FILE=pool-metadata.json
echo '{
  "name": "Test",
  "description": "Test",
  "ticker": "TEST",
  "homepage": "https://example.com"
}' > $METADATA_FILE
export METADATA_HASH=`cardano-cli latest stake-pool metadata-hash --pool-metadata-file pool-metadata.json`

#
export RELAY_IPV4="87.227.245.188"
export RELAY_HOST="static.87.227.245.188.clients.your-server.de"
export RELAY_PORT=3000

export STAKE_DEPOSIT_AMOUNT=2000000
```

### Generate Keys


```bash
# Generate cold keys (not to be copied)
# cold.vkey, cold.skey and opcert.counter
cardano-cli latest node key-gen \
  --cold-verification-key-file cold.vkey \
  --cold-signing-key-file cold.skey \
  --operational-certificate-issue-counter-file opcert.counter

# Generate payment keys
cardano-cli latest address key-gen \
  --verification-key-file payment.vkey \
  --signing-key-file payment.skey

# Generate stake keys
cardano-cli latest stake-address key-gen \
  --verification-key-file stake.vkey \
  --signing-key-file stake.skey

# Generate the payment address
cardano-cli latest address build \
  --payment-verification-key-file payment.vkey \
  --stake-verification-key-file stake.vkey \
  --testnet-magic 2 \
  --out-file payment.addr

# Generate KES keys
# kes.vkey, kes.skey
cardano-cli latest node key-gen-KES \
  --verification-key-file kes.vkey \
  --signing-key-file kes.skey

# Generate VRF keys
# vrf.vkey and vrf.skey
cardano-cli latest node key-gen-VRF \
  --verification-key-file vrf.vkey \
  --signing-key-file vrf.skey

cardano-cli latest stake-pool registration-certificate \
  --cold-verification-key-file cold.vkey \
  --vrf-verification-key-file vrf.vkey \
  --pool-pledge $PLEDGE \
  --pool-cost $COST \
  --pool-margin $MARGIN \
  --pool-reward-account-verification-key-file stake.vkey \
  --pool-owner-stake-verification-key-file stake.vkey \
  --testnet-magic $TESTNET_MAGIC \
  --pool-relay-ipv4 $RELAY_IPV4 \
  --pool-relay-port $RELAY_PORT \
  --single-host-pool-relay $RELAY_HOST \
  --metadata-url $METADATA_FILE \
  --metadata-hash $METADATA_HASH \
  --out-file pool-registration.cert

cardano-cli latest stake-address registration-certificate \
  --key-reg-deposit-amt $STAKE_DEPOSIT_AMOUNT \
  --stake-verification-key-file stake.vkey \
  --out-file registration.cert

cardano-cli latest stake-address stake-delegation-certificate \
  --stake-verification-key-file stake.vkey \
  --cold-verification-key-file cold.vkey \
  --out-file stake-delegation.cert

cardano-cli latest stake-pool id \
  --output-format bech32 > pool_id.bech32
```
