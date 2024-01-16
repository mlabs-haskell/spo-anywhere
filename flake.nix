{
  inputs = {
    cardanoNix.url = "github:mlabs-haskell/cardano.nix";

    nixpkgs.follows = "cardanoNix/nixpkgs";
    flake-parts.follows = "cardanoNix/flake-parts";

    hercules-ci-effects.follows = "cardanoNix/hercules-ci-effects";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-root.url = "github:srid/flake-root";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devour-flake = {
      url = "github:srid/devour-flake";
      flake = false;
    };
    cardano-node.url = "github:intersectmbo/cardano-node?ref=8.7.3";

    iohkNix = {
      url = "github:input-output-hk/iohk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {
      inherit inputs;
    } {
      debug = true; # TODO: disable in the future
      imports = [
        ./lib
        ./checks
        ./ci
        ./formatter
        ./shell
        ./modules
        ./tests
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
}
