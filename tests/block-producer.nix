{inputs}: {pkgs, ...}: {
  spo-anywhere.tests = {
    block-producer = let
      waitNodeScript = machine: ''
        ${machine}.wait_for_unit("cardano-node.service")
        ${machine}.wait_for_open_port(12798) # prometheus
        ${machine}.wait_for_open_port(3001)  # node
        ${machine}.succeed("stat /run/cardano-node")
        ${machine}.succeed("stat /run/cardano-node/node.socket")
        ${machine}.succeed("systemctl status cardano-node")
      '';
      pingTestScript = machine: ''
        ${machine}.succeed(
          "cardano-cli ping -h 127.0.0.1 -p 3001 -c 1 --magic 1 -q --json \
            | ${pkgs.jq}/bin/jq '.pongs != null' \
            | grep -e '^true$'"
        )
      '';

      # common module between block producer and relays
      common = {
        config,
        pkgs,
        ...
      }: {
        networking = {
          useNetworkd = true;
          useDHCP = false;
          firewall = {
            enable = false;
            # allowedTCPPorts = [ 3001 ];
          };
        };
        virtualisation = {
          vlans = [1];
          cores = 2;
          memorySize = 1024;
          writableStore = false;
        };
        environment = {
          systemPackages = [
            config.services.cardano-node.cardanoNodePackages.cardano-cli
            pkgs.lsof
            pkgs.nmap
          ];
        };
      };
    in {
      systems = ["x86_64-linux"];

      module = {
        name = "block producer starts";

        nodes = {
          block_producer = {
            ...
          }: {
            imports = [common];
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
            # services.nginx = {
            #   enable = true;
            #   virtualHosts."block_producer" = {};
            # };
            # networking = {  # static ip
            #   interfaces = {
            #     ens3.ipv6.addresses = [{
            #       address = "2a01:4f8:1:4f8::";
            #       prefixLength = 64;
            #     }];
            #   };
            # };
            services.block-producer-node = {
              enable = true;
              relayAddrs = [
                {
                  # address = "2a01.4f8.2.4f8";
                  address = "192.168.1.1";
                  # address = "127.0.0.1";
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
            ...
          }: {
            imports = [common];
            services.nginx = {
              enable = true;
              virtualHosts."relay_node" = {};
            };
            # networking = {
            #   interfaces = {
            #     ens3.ipv6.addresses = [{
            #       address = "2a01:4f8:2:4f8::";
            #       prefixLength = 64;
            #     }];
            #   };
            # };
            services.relay-node = {
              enable = true;
              localAddrs = [
                {
                  # address = "2a01.4f8.1.4f8";
                  # address = "127.0.0.1";
                  address = "192.168.1.0";
                  port = 3001;
                }
              ];
            };
          };
        };

        testScript = ''
          start_all()
          ${waitNodeScript "block_producer"}
          ${waitNodeScript "relay_node"}
          ${pingTestScript "block_producer"}
          ${pingTestScript "relay_node"}
        '';
        # ${jq}/bin/jq -c"
      };
    };
  };
}
