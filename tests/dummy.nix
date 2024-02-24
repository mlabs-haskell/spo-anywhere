{
  perSystem.vmTests.tests.dummy.module = {
    nodes.machine = {pkgs, ...}: {
      environment.systemPackages = [pkgs.hello];
    };

    testScript = ''
      machine.succeed("hello")
    '';
  };
}
