
## Generate pool keys

We need 3 keys:

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
```

