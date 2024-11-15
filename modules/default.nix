{
  config,
  inputs,
  ...
}: {
  flake.nixosModules = {
    block-producer-node = import ./block-producer-node inputs;
    install-script = import ./install-script inputs;
    # the default module imports all modules
    default = {
      imports = with builtins; attrValues (removeAttrs config.flake.nixosModules ["default"]);
    };
  };
}
