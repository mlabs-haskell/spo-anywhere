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
            virtualisation = {
              cores = 2;
              memorySize = 1024;
              writableStore = false;
            };
            environment = {
              systemPackages = [config.services.cardano-node.cardanoNodePackages.cardano-cli];
              # We provide keys in copy mode with correct permissions - otherwise cardano-node rejects.
              etc = {
                node-kes-skey = {
                  source = ./block-producer-keys/kes.skey;
                  mode = "400";
                  user = "cardano-node";
                };
                node-vrf-skey = {
                  source = ./block-producer-keys/vrf.skey;
                  mode = "400";
                  user = "cardano-node";
                };
                node-opcert-cert = {
                  source = ./block-producer-keys/opcert.cert;
                  mode = "400";
                  user = "cardano-node";
                };
              };
            };
            services.block-producer-node = {
              enable = true;
              relayAddrs = [
                {
                  address = "x.x.x.x";
                  port = 3000;
                }
              ];
              key-paths = {
                node-kes-skey = "/etc/node-kes-skey";
                node-vrf-skey = "/etc/node-vrf-skey";
                node-opcert-cert = "/etc/node-opcert-cert";
              };
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
