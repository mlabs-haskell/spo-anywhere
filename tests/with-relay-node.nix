{
  self,
  inputs,
  ...
}: {
  perSystem = {config, ...}: {
    spo-anywhere.tests = let
      # listing both addresses
      topology = self.lib.mkBlockProducerTopology [
        {
          "address" = "192.168.1.1";
          port = 3001;
        }
        {
          "address" = "192.168.1.0";
          port = 3001;
        }
      ];
    in {
      relay-node = {
        systems = ["x86_64-linux"];

        module = {
          name = "block producer accessed via relay node";

          nodes = {
            producer = {lib, ...}: {
              imports = [(import ./hosts/block-producer.nix {inherit inputs;})];
              config = {
                virtualisation.vlans = [1];
                services.cardano-node = {
                  topology = lib.mkForce topology;
                  hostAddr = lib.mkForce "0.0.0.0";
                };
              };
            };
            relay = {lib, ...}: {
              imports = [(import ./hosts/block-producer.nix {inherit inputs;})];
              config = {
                virtualisation.vlans = [1];
                services.cardano-node = {
                  topology = lib.mkForce topology;
                  hostAddr = lib.mkForce "0.0.0.0";
                };
                spo-anywhere.node = {
                  block-producer-key-path = lib.mkForce null;
                };
              };
            };
          };

          # Spend some transaction with relay node, check if producer mines it
          testScript = ''
            start_all()
            producer.wait_for_unit("cardano-node.service")
            producer.wait_for_open_port(3001)
            producer.succeed("stat /run/cardano-node")
            producer.succeed("stat /run/cardano-node/node.socket")
            producer.succeed("systemctl status cardano-node")
            relay.wait_for_unit("cardano-node.service")
            relay.wait_for_open_port(3001)
            relay.succeed("stat /run/cardano-node")
            relay.succeed("stat /run/cardano-node/node.socket")
            relay.succeed("systemctl status cardano-node")
            print(relay.succeed("spend-utxo"))
          '';
        };
      };
    };
  };
}
