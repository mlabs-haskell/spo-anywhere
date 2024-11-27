{config, ...}: {
  flake.templates = {
    default = {
      path = ./default;
      description = "Example flake using spo-anywhere";
    };
  };
}
