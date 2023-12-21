{inputs, ...}: {
  imports = [
    inputs.hercules-ci-effects.flakeModule
    # to be updated to import a flake output
    "${inputs.hercules-ci-effects}/effects/populate-cache/default.nix"
  ];
  herculesCI.ciSystems = ["x86_64-linux" "x86_64-darwin"];
  hercules-ci.populate-cache-effect = {
    enable = true;
    attic-client-pkg = inputs.attic.packages.x86_64-linux.attic-client;
    caches = {
      mlabs-spo-anywhere = {
        type = "attic";
        secretName = "spo-anywhere-cache-push-token";
        packages = [inputs.nixpkgs.legacyPackages.x86_64-linux.hello];
      };
    };
  };
}
