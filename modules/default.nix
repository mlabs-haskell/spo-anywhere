{
  config,
  inputs,
  ...
}: {
  flake.nixosModules = {
    module = ./dummy;
    block-producer-node = import ./block-producer-node inputs;
    dummy = import ./dummy;
    deploy-script = import ./deploy-script;
    # the default module imports all modules
    default = {
      imports = with builtins; attrValues (removeAttrs config.flake.nixosModules ["default"]);
    };
  };
}
