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
    sidebarOptions = [
      {
        anchor = "spo-anywhere.node";
        modules = [config.flake.nixosModules.block-producer-node];
        namespaces = ["spo-anywhere.node"];
      }
      {
        anchor = "services.cardano-node";
        modules = [
          config.flake.nixosModules.block-producer-node
          # FIXME Without this, using recent cardano-node
          # versions, the documentation generation fails
          # It doesn't seem to add any explicit network reference
          {
            services.cardano-node.environment = "mainnet"; # arbitrary value
          }
        ];
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
