{
  config,
  inputs,
  ...
}: {
  flake.nixosModules = {
    module = ./dummy;
    block-producer-node = import ./block-producer-node {inherit inputs;};
    dummy = import ./dummy;
    # the default module imports all modules
    default = {
      imports = with builtins; attrValues (removeAttrs config.flake.nixosModules ["default"]);
    };
  };
}
