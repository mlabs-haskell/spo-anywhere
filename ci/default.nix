{
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.hercules-ci-effects.flakeModule
    ./all-flake-drvs.nix
    inputs.hercules-ci-effects.push-cache-effect
  ];
  herculesCI.ciSystems = ["x86_64-linux" "x86_64-darwin"];
  allDrvs.systems = [
    "x86_64-linux"
  ];
  push-cache-effect = {
    enable = true;
    attic-client-pkg = inputs.attic.packages.x86_64-linux.attic-client;
    caches = {
      mlabs-spo-anywhere = {
        type = "attic";
        secretName = "spo-anywhere-cache-push-token";
        packages = config.allDrvs.list;
      };
    };
  };
}
