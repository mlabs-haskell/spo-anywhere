#!/usr/bin/env bash

set -xe

TESTNET_MAGIC=${TESTNET_MAGIC:-2}

cardano-cli latest transaction build \
  --testnet-magic $TESTNET_MAGIC \
  --witness-override 2 \
  --tx-in $(cardano-cli query utxo --address $(cat payment.addr) --testnet-magic $TESTNET_MAGIC --out-file  /dev/stdout | jq -r 'keys[0]') \
  --change-address $(cat payment.addr) \
  --certificate-file registration.cert \
  --out-file tx.raw

cardano-cli latest transaction sign \
  --tx-body-file tx.raw \
  --signing-key-file payment.skey \
  --signing-key-file stake.skey \
  --testnet-magic $TESTNET_MAGIC \
  --out-file tx.signed

cardano-cli latest transaction submit \
  --testnet-magic 2 \
  --tx-file tx.signed 
