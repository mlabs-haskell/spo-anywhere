{
  inputs = {
    cardanoNix.url = "github:mlabs-haskell/cardano.nix";

    # Follow versions from cardano.nix
    nixpkgs.follows = "cardanoNix/nixpkgs";
    flake-parts.follows = "cardanoNix/flake-parts";

    # we use effects for CI and documentation
    hercules-ci-effects.follows = "cardanoNix/hercules-ci-effects";

    # Utilities
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
      debug = true;
      imports = [
        ./lib
        ./checks
        ./ci
        ./formatter
        ./shell
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
}
