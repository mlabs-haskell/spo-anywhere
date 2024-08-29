{
  description = "Example flake using cardano.nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    spo-anywhere = {
      url = "github:mlabs-haskell/spo-anywhere\?ref=karol/milestone4";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
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
    // rec {
      nixosModules = rec {
        hardware = {
          imports = [
            (import ./modules/hardware.nix)
            disko.nixosModules.disko
          ];
        };
        spo = {
          imports = [
            spo-anywhere.nixosModules.default
          ];
          config = {
            spo-anywhere = {
              install-script.enable = true;
              # optional: specify the target host for the install script here. Otherwise overwrite in cli.
              install-script.target-host = "root@my-ip";
              node = {
                enable = true;
                # optional: put all configs here, i.e. with `etc.tmpfiles`
                # configFilesPath = "/etc/spo/configs";
                block-producer-key-path = "/var/lib/spo";
              };
            };
            services.cardano-node = {
              # specify the node configuration directly or by specifying an environment
              environment = "mainnet";
              # specify the topology, directly like here or with `producers`, `publicProducers` and `usePeersFromLedgerAfterSlot` options.
              topology = ../tests/local-testnet-config/topology-spo-1.json;
              # example overwrites:
              stateDir = "/var/lib/cardano-node";
              runtimeDir = "/run/cardano-node";
            };
          };
        };
        spo-on-digital-ocean = {modulesPath, ...}: {
          imports = [
            "${modulesPath}/virtualisation/digital-ocean-config.nix"
            spo
            hardware
          ];
        };
        default = spo-on-digital-ocean;
      };
      nixosConfigurations = rec {
        default = spo;
        spo = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            nixosModules.default
          ];
        };
      };
    };
}
