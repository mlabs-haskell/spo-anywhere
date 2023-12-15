{config, ...}: {
  flake.nixosModules = {
    module = ./dummy;
    # the default module imports all modules
    default = {
      imports = with builtins; attrValues (removeAttrs config.flake.nixosModules ["default"]);
    };
  };
}
