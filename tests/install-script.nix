inputs: { config, pkgs, ... }: {
  spo-anywhere.tests = {
    install-script = let
    ssh-keys = pkgs.runCommand "install-test-ssh-keys" {} ''
      mkdir $out
      ${pkgs.openssh}/bin/ssh-keygen -f $out/my_key -P ""
    '';
    installing = {
      imports = [
        # common
        # self.nixosModules.default <- can't do, so:
        (import ../modules/install-script )
        # (import ./disko.nix inputs)
        (import ./system-to-install.nix inputs)
        # (import ../modules/block-producer.nix inputs)
      ];
      config = {
        networking.hostName = "spo-anywhere-welcomes";
        spo-anywhere.install-script.enable = true;
      };
    };
    # TODO: how to test other systems?
    system = "x86_64-linux";
    install-script = (inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        installing
      ];
    }).config.system.build.spoInstallScript;
    in {
      systems = [system];

      module = {config, ...}:
        {
        name = "install script";

        nodes = {
          installer = {
            pkgs,
            lib,
            ...
          }: {
            virtualisation = {
              cores = 2;
              memorySize = 1512;
              # writableStore = false;
            };
            system.activationScripts.rsa-key = ''
              ${pkgs.coreutils}/bin/install -D -m600 ${ssh-keys}/my_key /root/.ssh/install_key
            '';
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
                # spo-install-script --target root@host --spo-keys . --ssh-key ./ssh-keys
              })
              ];
            };
          installed = {
            services.openssh.enable = true;
            virtualisation.memorySize = 1512;
            users.users.root.openssh.authorizedKeys.keyFiles = [ "${ssh-keys}/my_key.pub" ];
          };
        };
        testScript = ''
          def create_test_machine(oldmachine=None, args={}): # taken from <nixpkgs/nixos/tests/installer.nix>
              startCommand = "${pkgs.qemu_test}/bin/qemu-kvm"
              startCommand += " -cpu max -m 1024 -virtfs local,path=/nix/store,security_model=none,mount_tag=nix-store"
              startCommand += f' -drive file={oldmachine.state_dir}/installed.qcow2,id=drive1,if=none,index=1,werror=report'
              startCommand += ' -device virtio-blk-pci,drive=drive1'
              machine = create_machine(
                start_command=startCommand,
                **args)
              driver.machines.append(machine)
              return machine
          start_all()
          ssh_key_path = "/etc/ssh/ssh_host_ed25519_key.pub"
          print("STOP before getting ssh keys")
          ssh_key_output = installer.wait_until_succeeds(f"""
            ssh -i /root/.ssh/install_key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
              root@installed cat {ssh_key_path}
          """)
          print(installer.execute("""
            install-spo
          """, timeout=15*60))
          try:
            installed.shutdown()
          except BrokenPipeError:
            # qemu has already exited
            pass
          new_machine = create_test_machine(oldmachine=installed, args={ "name": "after_install"})
          new_machine.start()
          new_machine.systemctl("status backdoor.service")
          new_machine.shutdown()
          hostname = new_machine.succeed("hostname").strip()
          assert "spo-anywhere-welcomes" == hostname, f"'spo-anywhere-welcomes' != '{hostname}'"
          ssh_key_content = new_machine.succeed(f"cat {ssh_key_path}").strip()
          assert ssh_key_content in ssh_key_output, "SSH host identity changed"
        '';
      };
    };
  };
}
