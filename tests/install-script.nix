{inputs, ...}: {pkgs, ...}: let
  ssh-keys = pkgs.runCommand "install-test-ssh-keys" {} ''
    mkdir $out
    ${pkgs.openssh}/bin/ssh-keygen -f $out/my_key -P ""
  '';
  installing = {lib, ...}: {
    imports = [
      # self.nixosModules.default <- can't do, so:
      (import ../modules/install-script {inherit inputs;})
      (import ./system-to-install.nix inputs)
      (import ../modules/block-producer-node inputs)
    ];
    config = {
      networking.hostName = "spo-anywhere-welcomes";
      spo-anywhere = {
        install-script.enable = true; # true by default
        node = {
          enable = true;
          configFilesPath = "/etc/spo/configs";
          block-producer-key-path = "/var/lib/spo";
        };
      };
      systemd.tmpfiles.rules = [
        "C+ /etc/spo/configs - - - - ${./local-testnet-config}"
        "Z /etc/spo/configs 700 cardano-node cardano-node - ${./local-testnet-config}" # z lines dont take argument fields, ignoring
      ];

      systemd.services.cardano-node.preStart = ''
        NOW=$(date +%s -d "now + 5 seconds")
        ${lib.getExe pkgs.yq-go} e -i ".startTime = $NOW" /etc/spo/configs/byron-gen-command/genesis.json
      '';

      environment.systemPackages = [
        (import ./spend-utxo-testscript.nix {inherit inputs pkgs;})
      ];
    };
  };
  system = "x86_64-linux";
  install-script-config = nixos-config:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        nixos-config
      ];
    };
  install-script = nixos-config: (install-script-config nixos-config).config.system.build.spoInstallScript;

  systems = [system];

  installer = install-script: {pkgs, ...}: {
    virtualisation = {
      cores = 2;
      memorySize = 1512;
      writableStore = true;
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
    };
    networking.firewall.enable = false;
    system.activationScripts.rsa-key = ''
      ${pkgs.coreutils}/bin/install -D -m600 ${ssh-keys}/my_key /root/.ssh/install_key
    '';
    services.openssh.enable = true;

    environment.systemPackages = [
      pkgs.nixos-anywhere
      (pkgs.writeShellApplication {
        name = "install-spo";
        runtimeInputs = [
          install-script
        ];
        text = ''
          set -x
          mkdir -p spo-keys/byron-gen-command spo-keys/pools
          cp ${./local-testnet-config}/pools/kes1.skey spo-keys/pools/kes1.skey
          cp ${./local-testnet-config}/pools/vrf1.skey spo-keys/pools/vrf1.skey
          cp ${./local-testnet-config}/pools/opcert1.cert spo-keys/pools/opcert1.cert
          cp ${./local-testnet-config}/byron-gen-command/delegate-keys.000.key spo-keys/byron-gen-command/delegate-keys.000.key
          cp ${./local-testnet-config}/byron-gen-command/delegation-cert.000.json spo-keys/byron-gen-command/delegation-cert.000.json

          ls -laR ./spo-keys
          sh -ex spo-install-script --target root@installed --spo-keys ./spo-keys --ssh-key /root/.ssh/install_key
        '';
      })
      (pkgs.writeShellApplication {
        name = "install-spo-no-target";
        runtimeInputs = [
          install-script
        ];
        text = ''
          mkdir -p spo-keys/byron-gen-command spo-keys/pools
          cp ${./local-testnet-config}/pools/kes1.skey spo-keys/pools/kes1.skey
          cp ${./local-testnet-config}/pools/vrf1.skey spo-keys/pools/vrf1.skey
          cp ${./local-testnet-config}/pools/opcert1.cert spo-keys/pools/opcert1.cert
          cp ${./local-testnet-config}/byron-gen-command/delegate-keys.000.key spo-keys/byron-gen-command/delegate-keys.000.key
          cp ${./local-testnet-config}/byron-gen-command/delegation-cert.000.json spo-keys/byron-gen-command/delegation-cert.000.json

          spo-install-script --spo-keys ./spo-keys --ssh-key /root/.ssh/install_key --target
        '';
      })
    ];
  };
  installed = {
    services.openssh.enable = true;
    networking.firewall.enable = false;
    virtualisation = {
      memorySize = 3000;
      diskSize = 3500;
      cores = 2;
      writableStore = true;
    };
    users.users.root.openssh.authorizedKeys.keyFiles = ["${ssh-keys}/my_key.pub"];
  };
  testScript = test-install: ''
    def main():
        start_all()

        ssh_key_path = "/etc/ssh/ssh_host_ed25519_key.pub"
        ssh_key_output = installer.wait_until_succeeds(f"""
          ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
            root@installed cat {ssh_key_path}
          """)
        ${test-install}
        try:
            installed.shutdown()
        except BrokenPipeError:
            # qemu has already exited
            pass
        new_machine = create_test_machine(oldmachine=installed, args={ "name": "after_install"})
        new_machine.start()
        (_, hostname) = new_machine.execute("hostname")
        hostname = hostname.strip()
        assert "spo-anywhere-welcomes" == hostname, f"'spo-anywhere-welcomes' != '{hostname}'"
        ssh_key_content = new_machine.succeed(f"cat {ssh_key_path}").strip()
        assert ssh_key_content in ssh_key_output, "SSH host identity changed"

        # For easy debugging -- display rights for keys matherial
        print(new_machine.succeed("ls -laR /var/lib/spo"))
        new_machine.wait_for_unit("cardano-node")
        new_machine.wait_until_succeeds("test -e /run/cardano-node/node.socket")

        print(new_machine.succeed("spend-utxo"))

    def create_test_machine(oldmachine=None, args={}): # taken from <nixpkgs/nixos/tests/installer.nix>
        startCommand = "${pkgs.qemu_test}/bin/qemu-kvm"
        startCommand += " -cpu max -m 5000 -virtfs local,path=/nix/store,security_model=none,mount_tag=nix-store"
        startCommand += f' -drive file={oldmachine.state_dir}/installed.qcow2,id=drive1,if=none,index=1,werror=report'
        startCommand += ' -device virtio-blk-pci,drive=drive1'
        machine = create_machine(
          start_command=startCommand,
          keep_vm_state=True,
          **args)
        driver.machines.append(machine)
        return machine

    main()
  '';
in {
  spo-anywhere.tests = {
    install-script-overwrite-target = {
      inherit systems;
      module = _: {
        name = "install script overwriting target in cli";
        nodes = {
          inherit installed;
          installer = installer (
            install-script {
              imports = [installing];
              config = {
                spo-anywhere.install-script.target = "some-invalid-garbage";
              };
            }
          );
        };
        testScript = testScript "print(installer.succeed(\"install-spo\"))";
      };
    };
    install-script = {
      inherit systems;
      module = _: {
        name = "install script target as nixos option";
        nodes = {
          inherit installed;
          installer = installer (
            install-script {
              imports = [installing];
              config = {
                spo-anywhere.install-script.target = "root@installed";
              };
            }
          );
        };
        testScript = testScript "print(installer.succeed(\"install-spo\"))";
      };
    };
    install-script-target-missing = {
      inherit systems;
      module = _: {
        name = "install script no target provided";
        nodes = {
          inherit installed;
          installer = installer (install-script installing);
        };
        testScript = testScript ''
          print(installer.fail("install-spo-no-target")); return None
        '';
      };
    };
  };
}
