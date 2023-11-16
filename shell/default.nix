{inputs, ...}: {
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = {
    pkgs,
    config,
    ...
  }: {
    devshells.default = {
      devshell = {
        name = "SPO Anywhere";
        motd = ''
          ❄️ Welcome to the {14}{bold}SPO Anywhere{reset}'s shell ❄️
          $(type -p menu &>/dev/null && menu)
        '';
      };
      packages = with pkgs; [
        statix
        config.treefmt.build.wrapper
      ];
    };
  };
}
