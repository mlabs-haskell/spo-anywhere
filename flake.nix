{
  inputs = {
    # cardanoNix.url = "github:mlabs-haskell/cardano.nix";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # TODO: use upstream `hercules-ci-effects` once this is merged:
    # https://github.com/hercules-ci/hercules-ci-effects/pull/165/
    # hercules-ci-effects.follows = "cardanoNix/hercules-ci-effects";
    hercules-ci-effects.url = "github:mlabs-haskell/hercules-ci-effects/push-cache-effect";

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
    cardano-node.url = "github:intersectmbo/cardano-node?ref=8.1.2";
    cardano-addressses.url = "github:intersectmbo/cardano-addresses";
    cardano-world = {
      url = "github:IntersectMBO/cardano-world";
      # inputs.nixpkgs.follows = "nixpkgs";
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
        ./apps
      ];
      systems = [
        "x86_64-linux"
        # "aarch64-linux"
        # "x86_64-darwin"
        # "aarch64-darwin"
      ];
    };
}
