{
  inputs = {
    # TODO go back to `main` once merged
    spo-anywhere.url = "../..";
    srvos.url = "github:nix-community/srvos";
    nixpkgs.follows = "srvos/nixpkgs";
    disko.follows = "spo-anywhere/disko";
  };
  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    spo-anywhere,
    srvos,
    disko,
    ...
  }:
    flake-parts.lib.mkFlake {
      inherit inputs;
    } ({config, ...}: {
      systems = [
        "x86_64-linux"
      ];
      flake.nixosConfigurations.spo-node-hetzner = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          spo-anywhere.nixosModules.default
          srvos.nixosModules.server
          srvos.nixosModules.hardware-hetzner-cloud
          disko.nixosModules.disko
          ./configuration.nix
          ./disko.nix
          {_module.args = {inherit inputs;};}
        ];
      };
      perSystem = _: {
        packages = {
          install = config.flake.nixosConfigurations.spo-node-hetzner.config.system.build.spoInstallScript;
        };
      };
    });
}
