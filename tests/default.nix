{ config, ...}:
{
  perSystem = _: {
    imports = [
      ./dummy.nix
      (import ./block-producer.nix { node-module = config.flake.nixosModules.block-producer-node; })
    ];
  };
}
