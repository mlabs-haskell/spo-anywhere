{inputs, ...}: {
  config,
  pkgs,
  ...
}: {
  spo-anywhere.tests = {
    install-script = let
      ssh-keys = pkgs.runCommand "install-test-ssh-keys" {} ''
        mkdir $out
        ${pkgs.openssh}/bin/ssh-keygen -f $out/my_key -P ""
      '';
      installing = {
        imports = [
          # self.nixosModules.default <- can't do, so:
          (import ../modules/install-script {inherit inputs;})
          (import ./system-to-install.nix inputs)
        ];
        config = {
          networking.hostName = "spo-anywhere-welcomes";
          spo-anywhere.install-script.enable = true;
        };
      };
      # TODO: how to test other systems?
      system = "x86_64-linux";
      install-script-config = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          installing
        ];
      };
      install-script = install-script-config.config.system.build.spoInstallScript;
    in {
      systems = [system];

      module = _: {
        name = "install script";

        nodes = {
          installer = {pkgs, ...}: {
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
                  mkdir spo-keys
                  touch spo-keys/some-key
                  chmod -R 600 spo-keys

                  spo-install-script --target root@installed --spo-keys ./spo-keys --ssh-key /root/.ssh/install_key
                '';
              })
            ];
          };
          installed = {
            services.openssh.enable = true;
            networking.firewall.enable = false;
            virtualisation = {
              memorySize = 1512;
              diskSize = 2048;
              cores = 2;
              writableStore = true;
            };
            users.users.root.openssh.authorizedKeys.keyFiles = ["${ssh-keys}/my_key.pub"];
          };
        };
        testScript = ''
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
          start_all()
          ssh_key_path = "/etc/ssh/ssh_host_ed25519_key.pub"
          ssh_key_output = installer.wait_until_succeeds(f"""
            ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
              root@installed cat {ssh_key_path}
          """)
          print(installer.succeed("install-spo"))
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
        '';
      };
    };
  };
}
