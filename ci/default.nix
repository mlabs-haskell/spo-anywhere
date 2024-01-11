{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.hercules-ci-effects.flakeModule
    ./all-flake-drvs.nix
    # to be updated to import a flake output
    "${inputs.hercules-ci-effects}/effects/push-cache/default.nix"
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
