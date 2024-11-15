#!/usr/bin/env bash

set -xe

source vars.sh

cardano-cli node issue-op-cert --kes-verification-key-file tmp/kes.vkey \
  --cold-signing-key-file tmp/cold.skey \
  --operational-certificate-issue-counter-file tmp/opcert.counter \
  --kes-period $1 \
  --out-file tmp/opcert.cert
