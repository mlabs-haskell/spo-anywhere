{inputs, ...}: {
  imports = [
    inputs.hercules-ci-effects.flakeModule
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
  };
}
