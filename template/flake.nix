{
  description = "Example flake using cardano.nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    spo-anywhere.url = "github:mlabs-haskell/spo-anywhere/main";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    flake-utils,
    spo-anywhere,
    ...
  }:
    (
      flake-utils.lib.eachSystem ["x86_64-darwin" "x86_64-linux"]
      (system: {
        devShells = {
          default = spo-anywhere.devShells.${system}.spo-shell;
        };
      })
    )
    // {
      nixosModules = {
        hardware = {
        };
        default = {}: {
          imports = [
          ];
          config = {
            services.cardano-node = {
              # example overwrite
              stateDir = "/var/lib/cardano-node";
            };
          };
        };
      };
    };
}
