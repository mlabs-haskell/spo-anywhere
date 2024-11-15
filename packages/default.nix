{
  perSystem = {inputs', ...}: {
    packages = {
      inherit (inputs'.cardano-nix.packages) cardano-node cardano-cli;
    };
  };
}
