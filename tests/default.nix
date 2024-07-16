{inputs, ...}: {
  imports = [
    (import ./block-producer.nix {inherit inputs;})
    (import ./with-relay-node.nix)
  ];
  perSystem = _: {
    imports = [
      ./dummy.nix
      (import ./install-script.nix {inherit inputs;})
    ];
  };
}
