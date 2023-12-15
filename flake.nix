{
  inputs = {
    cardanoNix.url = "github:mlabs-haskell/cardano.nix";

    nixpkgs.follows = "cardanoNix/nixpkgs";
    flake-parts.follows = "cardanoNix/flake-parts";

    # TODO: use upstream `hercules-ci-effects` once this is merged:
    # https://github.com/hercules-ci/hercules-ci-effects/pull/163/
    # hercules-ci-effects.follows = "cardanoNix/hercules-ci-effects";
    hercules-ci-effects.url = "github:zmrocze/hercules-ci-effects/karol/push-cache-effect";

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
