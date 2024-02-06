{inputs}: {pkgs, ...}: {
  spo-anywhere.tests = {
    block-producer = let 
      pingTestScript = machine: ''
        ${machine}.wait_for_unit("cardano-node.service")
        ${machine}.wait_for_open_port(12798) # prometheus
        ${machine}.wait_for_open_port(3001)  # node
        ${machine}.succeed("stat /run/cardano-node")
        ${machine}.succeed("stat /run/cardano-node/node.socket")
        ${machine}.succeed("systemctl status cardano-node")
        ${machine}.succeed(
          "cardano-cli ping -h 127.0.0.1 -c 1 --magic 1 -q --json \
            | ${pkgs.jq}/bin/jq '.pongs != null' \
            | grep -e '^true$'"
        )
      '';
    
      # common module between block producer and relays
      common = {config, ... }: {
        virtualisation = {
          cores = 2;
          memorySize = 1024;
          writableStore = false;
        };
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 3001 ];
        };
        environment = {
          systemPackages = [config.services.cardano-node.cardanoNodePackages.cardano-cli];
        };
      };
      in {
      systems = ["x86_64-linux"];

      module = {
        name = "block producer starts";

        nodes = {
          block_producer = {
            config,
            pkgs,
            ...
          }: {
            imports = [ common ];
            environment = {
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
            services.nginx = {
              enable = true;
              virtualHosts."block_producer" = {};
            };
            services.block-producer-node = {
              enable = true;
              relayAddrs = [
                {
                  address = "relay_node";
                  port = 3001;
                }
              ];
              key-paths = {
                node-kes-skey = "/etc/node-kes-skey";
                node-vrf-skey = "/etc/node-vrf-skey";
                node-opcert-cert = "/etc/node-opcert-cert";
              };
            };
          };

          relay_node = {
            # config,
            pkgs,
            ...
          }: {
            imports = [ common ];
            services.nginx = {
              enable = true;
              virtualHosts."relay_node" = {};
            };
            services.relay-node = {
              enable = true;
              localAddrs = [
                {
                  address = "block_producer";
                  port = 3001;
                }
              ];
            };
          };
        };

        testScript = ''
          ${pingTestScript "block_producer"}
          ${pingTestScript "relay_node"}
        '';
        # ${jq}/bin/jq -c"
      };
    };
  };
}
