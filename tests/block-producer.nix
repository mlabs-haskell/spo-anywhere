{config, ...}: {
  perSystem = {inputs', ...}: {
    vmTests.tests.block-producer = {
      impure = true;
      module = {
        nodes.machine = {
          pkgs,
          lib,
          ...
        }: {
          imports = [
            config.flake.nixosModules.block-producer-node
          ];

          services.block-producer-node = {
            enable = true;
            environment = "preview";
            keyPaths = {
              kes-skey = "";
              vrf-skey = "";
              opcert-cert = "";
            };
          };

          services.cardano-node = {
            kesKey = lib.mkForce null;
            vrfKey = lib.mkForce null;
            operationalCertificate = lib.mkForce null;
          };

          environment = {
            systemPackages = with pkgs; [
              jq
              bc
              inputs'.cardano-node.packages.cardano-cli
            ];
            variables.CARDANO_NODE_SOCKET_PATH = "/run/cardano-node/node.socket";
          };
        };

        testScript = _: ''
          machine.wait_for_unit("cardano-node")
          machine.wait_until_succeeds("""[[ $(echo "$(cardano-cli query tip --testnet-magic 2 | jq '.syncProgress' --raw-output) > 0.001" | bc) == "1" ]]""")
        '';
      };
    };
  };
}
