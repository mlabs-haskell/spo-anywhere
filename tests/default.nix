{inputs, ...}: {
  perSystem = _: {
    imports = [
      ./dummy.nix
      (import ./block-producer.nix inputs)
      (import ./deploy-script.nix inputs)
    ];
  };
}
