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
        name = "SPO-anywhere";
        motd = ''
          ❄️ Welcome to the {14}{bold}SPO-anywhere{reset} devshell ❄️
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
