#!/usr/bin/env bash

set -ex

mkdir -p tmp
pushd tmp
rm -rf *

source vars.sh

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

popd
