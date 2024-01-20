{ config, inputs, ...}: let 

  relay-node = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      config.flake.nixosModules.relay-node
      {
        services.pipewire.enable = false;
        hardware.pulseaudio.enable = false;
      }
    ];
  };

in {

  flake.nixosConfigurations = {
    relay-node = relay-node;
  };

  flake.nixosModules = {
    module = ./dummy;
    relay-node = (import ./relay-node { inherit inputs; });
    # the default module imports all modules
    default = {
      imports = with builtins; attrValues (removeAttrs config.flake.nixosModules ["default"]);
    };
  };
}
