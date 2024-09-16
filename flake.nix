{
  inputs = {
    # FIXME more recent revisions breaks the docs
    nixpkgs.url = "github:NixOS/nixpkgs/58a1abdbae3217ca6b702f03d3b35125d88a2994";
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
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-images = {
      url = "github:nix-community/nixos-images";
    };
    cardano-nix.url = "github:mlabs-haskell/cardano.nix";
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {
      inherit inputs;
    } {
      imports = [
        ./lib
        ./checks
        ./ci
        ./docs
        ./formatter
        ./shell
        ./modules
        ./tests
        ./apps
      ];
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
      ];
      flake.templates.default = {
        path = ./template;
        description = "Example flake using spo-anywhere";
      };
    };
}
