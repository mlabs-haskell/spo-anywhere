{inputs, ...}: {
  perSystem.spo-anywhere.tests = {
    block-producer = {
      systems = ["x86_64-linux"];

      module = {
        name = "block producer";

        nodes = {
          producer = import ./hosts/block-producer.nix {inherit inputs;};
        };

        testScript = ''
          start_all()
          producer.wait_for_unit("cardano-node.service")
          producer.wait_for_open_port(3001)
          producer.succeed("stat /run/cardano-node")
          producer.succeed("stat /run/cardano-node/node.socket")
          producer.succeed("systemctl status cardano-node")
          print(producer.succeed("spend-utxo"))
        '';
      };
    };
  };
}
