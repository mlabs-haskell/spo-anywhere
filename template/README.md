# SPO flake template

## Deploy

```bash
$ nix build .\#nixosConfigurations.spo.config.system.build.spoInstallScript
$ ./result/bin/spo-install-script --target=root@my-cloud-server-address --ssh-key ~/.ssh/id_rsa --spo-keys ./spo-keys
```
