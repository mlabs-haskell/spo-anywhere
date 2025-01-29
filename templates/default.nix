{config, ...}: {
  flake.templates = {
    default = config.flake.templates.basic;
    basic = {
      path = ./basic;
      description = "Example flake using spo-anywhere";
    };
    cloud = {
      path = ./cloud;
      description = "Example flake using spo-anywhere in a cloud deployment";
    };
  };
}
