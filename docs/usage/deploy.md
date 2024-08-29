## Deploying

Once we defined a configuration at `.#nixosConfigurations.pool`, then running:

```bash
$ nix build .\#nixosConfigurations.pool.config.system.build.spoInstallScript
```

builds a script for deploying the configuration to a chosen cloud server (by default to `result`). You need the node keys from step 2.

Run:

```bash
$ ./result/bin/spo-install-script --target=root@my-cloud-server-address --ssh-key ~/.ssh/id_rsa --spo-keys ./spo-keys
```

providing the correct dns address for the remote server and an ssh private key allowed to ssh into that server.

When the command finishes with a success the server runs a cardano node. To allow it to operate as a stake pool it is left to register the node as a stake pool.
