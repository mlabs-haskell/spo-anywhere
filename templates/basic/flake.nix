{
  description = "Example flake using cardano.nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    spo-anywhere = {
      url = "github:mlabs-haskell/spo-anywhere/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    flake-utils,
    spo-anywhere,
    disko,
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
          imports = [
            (import ./modules/hardware.nix)
            disko.nixosModules.disko
          ];
        };
        default = {}: {
          imports = [
            spo-anywhere.nixosModules.default
          ];
          config = {
            spo-anywhere = {
              node = {
                enable = true;
                block-producer-key-path = "/var/lib/spo";
              };
            };
            services.cardano-node = {
              environment = "mainnet";
              # example overwrite
              stateDir = "/var/lib/cardano-node";
            };
          };
        };
      };
    };
}
