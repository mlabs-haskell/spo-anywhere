{inputs, ...}: {
  perSystem = _: {
    imports = [
      ./dummy.nix
      (import ./block-producer.nix inputs)
      (import ./install-script.nix inputs)
    ];
  };
}
