{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {
    pkgs,
    config,
    inputs',
    ...
  }: {
    devshells.default = {
      devshell = {
        name = "SPO-anywhere";
        motd = ''
          ❄️ Welcome to the {14}{bold}SPO-anywhere{reset} devshell ❄️
          $(type -p menu &>/dev/null && menu)
        '';
      };
      packages = with pkgs; [
        statix
	jq
        config.treefmt.build.wrapper
        inputs'.cardano-node.packages.cardano-cli
	inputs'.cardano-addressses.packages."cardano-addresses-cli:exe:cardano-address"
      ];
    };
  };
}
