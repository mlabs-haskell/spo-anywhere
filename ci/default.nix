{
  config,
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.hercules-ci-effects.flakeModule
    inputs.hercules-ci-effects.push-cache-effect
  ];
  config = {
    herculesCI = {
      ciSystems = ["x86_64-linux" "x86_64-darwin"];
    };
    hercules-ci.flake-update = {
      enable = true;
      when = {
        hour = [23];
        dayOfWeek = ["Sun"];
      };
    };
    push-cache-effect = {
      enable = true;
      caches = {
        mlabs-spo-anywhere = {
          type = "attic";
          secretName = "spo-anywhere-cache-push-token";
          packages = with lib;
            flatten [
              (forEach ["apps" "devShells" "packages"]
                (attr:
                  forEach config.systems
                  (system:
                    collect isDerivation (config.flake.${attr}.${system} or {}))))
              (forEach (attrValues config.flake.nixosConfigurations)
                (os:
                  os.config.system.build.toplevel))
            ];
        };
      };
    };
    hercules-ci.github-pages.branch = "main";
    perSystem = {config, ...}: {
      hercules-ci.github-pages.settings.contents = config.packages.docs;
    };
  };
}
