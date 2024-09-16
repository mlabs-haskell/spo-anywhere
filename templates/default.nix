{config, ...}: {
  flake.templates = {
    default = config.flake.templates.basic;
    basic = {
      path = ./basic;
      description = "Example flake using spo-anywhere";
    };
  };
}
