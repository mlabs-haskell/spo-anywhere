{
  spo-anywhere.tests = {
    dummy = {
      systems = ["x86_64-linux"];

      module = {
        name = "dummy-test";

        nodes = {
          machine = {
            virtualisation = {
              cores = 2;
              memorySize = 1024;
              writableStore = true;
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
