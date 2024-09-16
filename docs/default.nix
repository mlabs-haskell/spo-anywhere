{
  config,
  inputs,
  self,
  ...
}: {
  imports = [
    inputs.cardano-nix.flakeModules.docs
  ];

  renderDocs = {
    enable = true;
    name = "spo-anywhere";
    mkdocsYamlFile = ./mkdocs.yml;
    sidebarOptions = [
      {
        anchor = "spo-anywhere.node";
        modules = [config.flake.nixosModules.block-producer-node];
        namespaces = ["spo-anywhere.node"];
      }
      {
        anchor = "services.cardano-node";
        modules = [config.flake.nixosModules.block-producer-node];
        namespaces = ["services.cardano-node"];
      }
    ];

    # Replace `/nix/store` related paths with public urls
    fixups = [
      {
        storePath = self.outPath;
        githubUrl = "https://github.com/mlabs-haskell/spo-anywhere/tree/main";
      }
    ];
  };
}
