{ node-module }:
{ ... }: {
  spo-anywhere.tests = {
    block-producer = {
      systems = ["x86_64-linux"];

      module = {
        name = "block producer starts";

        nodes = {
          machine = { pkgs, ...}: {
            virtualisation = {
              cores = 2;
              memorySize = 1024;
              writableStore = true;
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
          machine.succeed("hello")
        '';
      };
    };
  };
}
