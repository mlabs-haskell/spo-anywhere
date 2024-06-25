{
  config,
  inputs,
  ...
}: {
  flake.nixosModules = {
    module = ./dummy;
    block-producer-node = import ./block-producer-node inputs;
    dummy = import ./dummy;
    install-script = import ./install-script {inherit inputs;};
    spo-anywhere = import ./spo-anywhere; # just a toplevel enable
    # the default module imports all modules
    default = {
      imports = with builtins; attrValues (removeAttrs config.flake.nixosModules ["default"]);
    };
  };
}
