{inputs, ...}: {
  imports = [
    (import ./block-producer.nix inputs)
    (import ./with-relay-node.nix)
  ];
  perSystem = _: {
    imports = [
      (import ./install-script.nix inputs)
    ];
  };
}
