{
  config,
  inputs,
  ...
}: {
  flake.nixosModules = {
    module = ./dummy;
    block-producer-node = import ./block-producer-node {inherit inputs;};
    relay-node = import ./relay-node {inherit inputs;};
    # the default module imports all modules
    default = {
      imports = with builtins; attrValues (removeAttrs config.flake.nixosModules ["default"]);
    };
  };
}
