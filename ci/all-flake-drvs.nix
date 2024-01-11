{
  self,
  config,
  lib,
  ...
}: {
  options.allDrvs = {
    systems = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = config.systems;
    };
    list = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default =
        lib.concatMap
        (system: (config.perSystem system).allDrvs._drvsList)
        config.allDrvs.systems;
    };
  };
  config.perSystem = {
    config,
    lib,
    system,
    ...
  }: let
    cfg = config.allDrvs;
  in {
    options.allDrvs = {
      outputs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = lib.intersectLists [
          "packages"
          "checks"
          "hydraJobs"
          "devShells"
          "legacyPackages"
        ] (lib.attrNames self.outputs);
      };
      _getStandardOutputs = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        internal = true;
        default =
          lib.concatMap
          (output: lib.attrValues config.${output})
          cfg.outputs;
      };
      formatter = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default =
          if config ? formatter
          then []
          else [config.formatter];
      };
      nixosConfigurations = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = let
          allConfigs =
            lib.lists.map
            (config: config.config.system.build.toplevel)
            (lib.attrValues self.nixosConfigurations);
        in
          lib.filter (drv: drv.system == system) allConfigs;
      };
      _drvsList = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        internal = true;
        default =
          cfg._getStandardOutputs
          ++ cfg.formatter
          ++ cfg.nixosConfigurations;
      };
    };
  };
}
