{...}: {
  imports = [
    (import ./block-producer.nix)
    (import ./with-relay-node.nix)
  ];
  perSystem = _: {
    imports = [
      ./dummy.nix
    ];
  };
}
