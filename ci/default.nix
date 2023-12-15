{inputs, ...}: {
  imports = [
    inputs.hercules-ci-effects.flakeModule
  ];
  herculesCI.ciSystems = ["x86_64-linux" "x86_64-darwin"];
  hercules-ci.populate-cache-effect = {
    enable = true;
    caches = {
      mlabs-spo-anywhere = {
        type = "attic";
        secretName = "spo-anywhere-cache-push-token";
        packages = inputs.nixpkgs.legacyPackages.x86_64-linux.hello;
      };
    };
  };
}
