{
  inputs = {
    spo-anywhere.url = "github:mlabs-haskell/spo-anywhere";
    srvos.url = "github:nix-community/srvos";
    nixpkgs.follows = "srvos/nixpkgs";
    disko.follows = "spo-anywhere/disko";
  };
  outputs = inputs @ {self, ...}: {
    nixosConfigurations.spo-node = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {_module.args = {inherit inputs;};}
        ./configuration.nix
        ./disko.nix
        inputs.spo-anywhere.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.srvos.nixosModules.server

        # To use a different cloud provider, change the line below to one of the moduels at
        # https://nix-community.github.io/srvos/nixos/hardware/
        inputs.srvos.nixosModules.hardware-amazon
      ];
    };
    packages.x86_64-linux.install = self.nixosConfigurations.spo-node.config.system.build.spoInstallScript;
  };
}
