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
        # Edit this module to configure the installation target
        ./target.nix

        # To use a different cloud provider, change the line below to one of the moduels at
        # https://nix-community.github.io/srvos/nixos/hardware/
        inputs.srvos.nixosModules.hardware-hetzner-cloud

        # This module may need to be edited to match the cloud provider disk configuration
        ./disko.nix

        # System configuration
        ./configuration.nix

        # Modules imported from inputs
        inputs.spo-anywhere.nixosModules.default
        inputs.disko.nixosModules.disko
        inputs.srvos.nixosModules.server
        {_module.args = {inherit inputs;};}
      ];
    };
    packages.x86_64-linux.install = self.nixosConfigurations.spo-node.config.system.build.spoInstallScript;
  };
}
