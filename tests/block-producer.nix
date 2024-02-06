{inputs}: {pkgs, ...}: {
  spo-anywhere.tests = {
    block-producer = {
      systems = ["x86_64-linux"];

      module = {
        name = "block producer starts";

        nodes = {
          machine = {
            config,
            pkgs,
            ...
          }: {
            imports = [
              # secrets module:
              # Ssh keys are provided in a derivation (not allowed in production!!)
              # Node keys by agenix - even in tests node keys have to be set dynamically, because cardano-node complains about 0555 /nix/store paths.
              # See [Note2 (node-keys)] for place of usage by node module.
              {
                imports = [ inputs.agenix.nixosModules.default ];
                environment.etc = {
                  "ssh_testnode" = {
                    source = ./block-producer-keys/ssh_testnode;
                    mode = "0555";
                  };
                  # "ssh-test-keys" = {
                  #   source =
                  #     let x = pkgs.runCommandLocal "testnode-ssh-keys" {} ''
                  #       mkdir "$out"
                  #       cp ${./block-producer-keys/ssh_testnode.pub} "$out"/ssh_testnode.pub
                  #       cp ${./block-producer-keys/ssh_testnode} "$out"/ssh_testnode
                  #     '';
                  #     in builtins.trace (builtins.toString x) x;
                  #   mode = "0555";
                  # };
                };

                # age.identityPaths = [ "/etc/ssh-test-keys/ssh_testnode" ];
                age.identityPaths = [ "/etc/ssh_testnode" ];

                age.secrets.node-kes-skey = {
                  file = ./block-producer-keys/kes.skey.age;
                  mode = "500";
                  owner = "cardano-node";
                };
                age.secrets.node-vrf-skey = {
                  file = ./block-producer-keys/vrf.skey.age;
                  # mode = "500";
                  mode = "777";
                  # owner = "cardano-node";
                };
                age.secrets.node-opcert-cert = {
                  file = ./block-producer-keys/opcert.cert.age;
                  mode = "500";
                  owner = "cardano-node";
                };
              }
            ];
            virtualisation = {
              cores = 2;
              memorySize = 1024;
              writableStore = false;
            };
            environment = {
              systemPackages = [config.services.cardano-node.cardanoNodePackages.cardano-cli];
            };
            services.block-producer-node = {
              enable = true;
              relayAddrs = [
                {
                  address = "x.x.x.x";
                  port = 3000;
                }
              ];
            };
          };
        };

        testScript = ''
          machine.wait_for_unit("cardano-node.service")
          machine.wait_for_open_port(12798) # prometheus
          machine.wait_for_open_port(3001)  # node
          machine.succeed("stat /run/cardano-node")
          machine.succeed("stat /run/cardano-node/node.socket")
          machine.succeed("systemctl status cardano-node")
          machine.succeed(
            "cardano-cli ping -h 127.0.0.1 -c 1 --magic 1 -q --json \
              | ${pkgs.jq}/bin/jq '.pongs != null' \
              | grep -e '^true$'"
          )
        '';
        # ${jq}/bin/jq -c"
      };
    };
  };
}
